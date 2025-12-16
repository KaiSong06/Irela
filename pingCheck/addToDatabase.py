import sqlite3
import pingTestUsed

def addToTable(hourNum: float, ping: int):

    # Connect to the database (or create one if it doesn't exist)
    connection = sqlite3.connect("example.db")
    cursor = connection.cursor()

    # Create a table (if not already created)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS users (
        hour INTEGER NOT NULL,
        averagePing INTEGER NOT NULL
    )
    """)

    # Insert data into the table
    cursor.execute("""
    INSERT INTO users (hour, averagePing) 
    VALUES (?, ?)
    """, (hourNum, ping))

    # Commit the changes and close the connection
    connection.commit()
    connection.close()

def accessTable():
    # Connect to the database
    connection = sqlite3.connect("example.db")
    cursor = connection.cursor()

    # Query to fetch all rows from the 'users' table
    cursor.execute("""
    SELECT * FROM users
    """)

    # Fetch and print the rows
    rows = cursor.fetchall()
    for row in rows:
        print(row)

    # Close the connection
    connection.close()


def deleteTable():
    # Connect to the database
    connection = sqlite3.connect("example.db")
    cursor = connection.cursor()

    # Drop the table if it exists
    cursor.execute("""
    DROP TABLE IF EXISTS users
    """)


def main():

    #Get time to test in days
    timeLengthDays = int(input("Length of time to test (Days): "))

    #Delete previous table to avoid errors
    deleteTable()

    #Compute ping per hour and implement to table
    for i in range(timeLengthDays*24):
        averagePingPerHour = pingTestUsed.getPing(1)
        addToTable(i+1, averagePingPerHour)
    
    #Output the table
    accessTable()

main()