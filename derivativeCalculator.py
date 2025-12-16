import math, sympy
from sympy import *
init_printing()


#Calculate derivarives
def getInput():
    equation = input("Equation: ")
    variable = symbols(input("With respect to variable: "))
    return equation, variable

def convertEquation(equation):
    return(sympy.sympify(equation))

def derive(equation, variable):
    return(sympy.diff(equation, variable))

#Setup pretty print




def main():
    print("Format: * - multiply, / - divide, ** - exponent, sqrt(x) - square root")

    equation, variable = getInput()
    pprint(derive(convertEquation(equation), variable), use_unicode=True)

if __name__ == "__main__":
    main()



