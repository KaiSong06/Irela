import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')
const GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface JournalEntry {
  date: string
  choice: string
  secondary_response?: string
  tertiary_response?: string
}

interface RequestBody {
  entries: JournalEntry[]
  depth: 'light' | 'reflect' | 'deep'
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { entries, depth }: RequestBody = await req.json()

    if (!entries || entries.length === 0) {
      return new Response(
        JSON.stringify({ insights: ["No check-ins yet this week.", "Come back after a few days."] }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!GEMINI_API_KEY) {
      console.error('GEMINI_API_KEY not configured')
      return new Response(
        JSON.stringify({ error: 'API key not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Build prompt from entries
    const prompt = buildPrompt(entries, depth)

    // Call Gemini API
    const response = await fetch(`${GEMINI_URL}?key=${GEMINI_API_KEY}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: depth === 'deep' ? 500 : depth === 'reflect' ? 400 : 300
        }
      })
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error('Gemini API error:', errorText)
      return new Response(
        JSON.stringify({ insights: getFallbackInsights(entries, depth) }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const data = await response.json()
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text || ''

    // Parse insights from response
    const insights = parseInsights(text, depth)

    console.log(`Generated ${insights.length} insights for ${entries.length} entries`)

    return new Response(
      JSON.stringify({ insights }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Edge function error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

function buildPrompt(entries: JournalEntry[], depth: string): string {
  let prompt = `You are a thoughtful, gentle journaling companion for a wellness app called "Calm Journal". 
Analyze the following weekly journal entries and provide personalized, warm insights.

Journal Entries from this week:
`

  // Sort entries by date
  const sortedEntries = [...entries].sort((a, b) => a.date.localeCompare(b.date))

  for (const entry of sortedEntries) {
    const formattedDate = formatDate(entry.date)
    prompt += `\n${formattedDate}:`
    prompt += `\n  Mood: ${entry.choice}`
    if (entry.secondary_response) {
      prompt += `\n  Context: ${entry.secondary_response}`
    }
    if (depth === 'deep' && entry.tertiary_response) {
      prompt += `\n  Deeper reflection: ${entry.tertiary_response}`
    }
  }

  prompt += '\n\n'

  // Add depth-specific instructions with character limits
  switch (depth) {
    case 'light':
      prompt += `Provide 2-3 gentle, simple insights. Each must be ONE short sentence under 80 characters. Focus on overall mood and simple observations.`
      break
    case 'reflect':
      prompt += `Provide 3-4 thoughtful insights. Each must be ONE sentence under 90 characters. Look for patterns and contrasts between days.`
      break
    case 'deep':
      prompt += `Provide 4-5 reflective insights. Each must be ONE sentence under 100 characters. Explore deeper patterns and emotional themes.`
      break
  }

  prompt += `

Important guidelines:
- Keep each insight SHORT (under 80-100 characters) — this is critical for mobile display
- Be gentle and non-judgmental
- Use phrases like "This week felt...", "You showed up...", "There seemed to be..."
- Acknowledge effort without being patronizing
- Don't give advice unless explicitly relevant
- End with something affirming about showing up

Format your response as a JSON array of strings, where each string is one insight.
Example: ["This week felt mostly calm.", "Midweek carried some weight.", "You showed up 5 days. That's enough."]`

  return prompt
}

function formatDate(dateString: string): string {
  try {
    const date = new Date(dateString + 'T12:00:00')
    return date.toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' })
  } catch {
    return dateString
  }
}

function parseInsights(text: string, depth: string): string[] {
  const maxInsights = depth === 'deep' ? 5 : depth === 'reflect' ? 4 : 3
  const maxChars = depth === 'deep' ? 100 : depth === 'reflect' ? 90 : 80

  try {
    // Clean up the response text
    let cleanedText = text.trim()

    // Remove markdown code blocks if present
    if (cleanedText.startsWith('```json')) {
      cleanedText = cleanedText.replace(/^```json\s*/, '').replace(/\s*```$/, '')
    } else if (cleanedText.startsWith('```')) {
      cleanedText = cleanedText.replace(/^```\s*/, '').replace(/\s*```$/, '')
    }

    // Try to extract JSON array
    const match = cleanedText.match(/\[[\s\S]*\]/)
    if (match) {
      const parsed = JSON.parse(match[0])
      if (Array.isArray(parsed) && parsed.length > 0) {
        return truncateInsights(parsed.slice(0, maxInsights), maxChars)
      }
    }

    // Try parsing the whole thing as JSON
    const parsed = JSON.parse(cleanedText)
    if (Array.isArray(parsed) && parsed.length > 0) {
      return truncateInsights(parsed.slice(0, maxInsights), maxChars)
    }
  } catch (e) {
    console.log('JSON parsing failed, trying fallback parsing')
  }

  // Fallback: try to extract numbered list
  const numberedRegex = /^\d+\.\s*(.+)$/gm
  const matches = [...text.matchAll(numberedRegex)]
  if (matches.length > 0) {
    return truncateInsights(matches.map(m => m[1].trim()).slice(0, maxInsights), maxChars)
  }

  // Last resort: split by newlines and filter
  const lines = text
    .split('\n')
    .map(line => line.trim())
    .filter(line => line.length > 15 && !line.startsWith('{') && !line.startsWith('['))
    .slice(0, maxInsights)

  if (lines.length > 0) {
    return truncateInsights(lines, maxChars)
  }

  // Return fallback insights
  return ["This week had its moments.", "You showed up. That matters."]
}

// Truncate insights that exceed character limit (safety net)
function truncateInsights(insights: string[], maxChars: number): string[] {
  return insights.map(insight => {
    if (insight.length <= maxChars) return insight
    // Truncate at last word boundary before limit
    const truncated = insight.slice(0, maxChars)
    const lastSpace = truncated.lastIndexOf(' ')
    if (lastSpace > maxChars * 0.6) {
      return truncated.slice(0, lastSpace) + '...'
    }
    return truncated + '...'
  })
}

function getFallbackInsights(entries: JournalEntry[], depth: string): string[] {
  const insights: string[] = []
  const count = entries.length

  // Basic mood analysis
  const choices = entries.map(e => e.choice.toLowerCase())
  const hasHeavy = choices.some(c => c.includes('heavy') || c.includes('down') || c.includes('overwhelmed'))
  const hasCalm = choices.some(c => c.includes('calm') || c.includes('good') || c.includes('clear'))

  if (hasCalm && !hasHeavy) {
    insights.push("This week felt mostly calm.")
  } else if (hasHeavy && !hasCalm) {
    insights.push("This week carried some weight.")
  } else {
    insights.push("This week had its moments.")
  }

  // Completion message
  if (count >= 5) {
    insights.push(`You showed up ${count} days. That's enough.`)
  } else if (count >= 3) {
    insights.push(`You checked in ${count} times this week.`)
  } else {
    insights.push(`You checked in ${count} time${count === 1 ? '' : 's'}. Every one matters.`)
  }

  return insights
}

