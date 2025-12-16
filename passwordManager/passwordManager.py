import os

def init():
        try:
                f = open("users.txt", "r")
                f.close
        except FileNotFoundError:
                with open("users.txt", "x") as file:
                        file.write("users, password")
        try:
                os.makedirs("userPasswords")
                
        except:
                pass
def getInput():
        user = input("User: ")
        password = input("Password: ")
        return user, password

def validatePassword(password):
        with open("users.txt", "r") as file:
                data = file.read().split("\n")
                for i in range(len(data)):
                        data[i] = data[i].split(",")
                for i in data:
                        if i[1].strip() == password:
                                return True
        return False

def addUser(user, password):
        #Check if user exists
        with open("users.txt", "r") as file:
                data = file.read().split("\n")
                for i in range(len(data)):
                        data[i] = data[i].split(",")

                for i in data:
                        if i[0] == user:
                                return False
        print(data)      
        #Add user and password
        with open("users.txt", "a") as file:
                file.write("\n")
                file.write(f"{user}, {password}")

        #Create a file for user
        f = open(os.path.join("userPasswords", user+".txt"), "x")
        f.close
        return True

def addPassword(user, webName, webUser, password):
        try:
                with open(os.path.join("userPasswords", user+".txt"), "a") as file:
                        file.write(f"{webName}, {webUser}, {password}")
                return True
        except FileNotFoundError:
                return False

def checkPassword(user, webName):
        try:
                with open(os.path.join("userPasswords", user+".txt"), "r") as file:
                        data = file.read().split("\n")
                        for i in range(len(data)):
                                data[i] = data[i].split(",")
                        for name in range(len(data)):
                                if data[i][0] == webName:
                                        return data[i][1], data[i][2]
        except FileNotFoundError:
                return False

def removePassword(user, webName):
        with open(os.path.join("userPasswords", user+".txt"), "r") as file:
                data = file.read().split("\n")
                for i in range(len(data)):
                        data[i] = data[i].split(",")
        for remove in range(len(data)):
                if data[remove][0] == webName:
                        data.pop(remove)
        with open(os.path.join("userPasswords", user+".txt"), "w") as file:
                for i in data:
                        file.write(f"{i[0]}, {i[1]}, {i[2]}\n")
                
def editPassword(user, webName, uOrP: bool): #True for username, False for password
        if uOrP != True:
                print("Invalid input")
        with open(os.path.join("userPasswords", user+".txt"), "r") as file:
                data = file.read().split("\n")
                for i in range(len(data)):
                        data[i] = data[i].split(",")
        if uOrP == True:
                newUser = str(input("New username: ")).strip()
                for remove in range(len(data)):
                        if data[remove][1] == webName:
                                data.pop(remove[1])
                                data.insert(1, newUser)
                with open(os.path.join("userPasswords", user+".txt"), "w") as file:
                        for i in data:
                                file.write(f"{i[0]}, {i[1]}, {i[2]}\n")
        
        elif uOrP == False:
                newPass = str(input("New password: ")).strip()
                for remove in range(len(data)):
                        if data[remove][1] == webName:
                                data.pop(remove[2])
                                data.insert(2, newPass)
                with open(os.path.join("userPasswords", user+".txt"), "w") as file:
                        for i in data:
                                file.write(f"{i[0]}, {i[1]}, {i[2]}\n")
        print(f"Made changes to {webName}")


def checkAddRemoveEdit(options, user):
        if options == "add":
                webName = str(input("Website name: ")).strip()
                webUser = str(input("Username or email: ")).strip()
                webPassword = str(input("Password: ")).strip()
                addPassword(user, webName, webUser, webPassword)
                print("Added")

        elif options == "check":
                webName = str(input("Website name: ")).strip()
                info = checkPassword(user, webName)
                if info == False:
                        print("Invalid website name")
                else:
                        print(f"Username: {info[0]}")
                        print(f"Password: {info[1]}")
        
        elif options == "remove":
                webName = str(input("Website name to be removed: ")).strip()
                removePassword(user, webName)
                print(f"Removed {webName}")
                
        elif options == "edit":
                webName = str(input("Website to be edited: ")).strip()
                uOrP = input("Change username or password?: ").strip().lower()
                if uOrP == "username":
                        uOrP = True
                        editPassword(user, webName, uOrP)
                elif uOrP == "password":
                        uOrP = False
                        editPassword(user, webName, uOrP)
                else:
                        print("Invalid input")
                
                
        
        else:
                print("Invalid input, try again")

def main():
        init()
        #Get user
        username, password = getInput()
        userAdded = addUser(username, password)
        
        running = True
        while running:
                #Check for user
                if userAdded == True:
                        print("User added")
                        userAdded = False


                elif userAdded == False:
                        validate = validatePassword(password)
                        if validate == False:
                                print("Invalid Password")
                        else:
                                print(f"Welcome {username}")
                                options = input("Check password or add password? (check/add): ").strip().lower()

                                #Add new password or check existing password
                                checkAddRemoveEdit(options, username)
                quit = input("quit or continue?: ").strip().lower()
                if quit == "quit":
                        running = False





main()


