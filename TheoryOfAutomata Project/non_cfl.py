def action(inp, rep, move):
    global tapehead
    if tape[tapehead] == inp:
        tape[tapehead] = rep
        if move == 'L':
            tapehead -= 1
        else:
            tapehead += 1
        return True
    return False

tape = ['B']*50
string = input("Enter a string: ")
i = 5
tapehead = 5
for s in string:
    tape[i] = s
    i += 1

state = 0
a, b, c, d, X, Z, U, V, R, L, B = 'a', 'b', 'c', 'd', 'X', 'Z', 'U', 'V', 'R', 'L', 'B'
oldtapehead = -1
accept = True
while(oldtapehead != tapehead): 
    oldtapehead = tapehead

    if state == 0:
        if action(a,  X, R):
           state = 1
        elif action(b, b, R):
            state = 4   

    elif state == 1:
        if action(a, a, R):
            state = 1
        elif action(b, b, R):
            state = 2

    elif state == 2:
        if action(b, b, R) or action(Z, Z, R):
            state = 2
        elif action(a, Z, L):
            state = 3

    elif state == 3:
        if action(b, b, L) or action(Z, Z, L) or action(a, a, L):
            state = 3
        elif action(X, X, R):
            state = 0

    elif state == 4:
        if action(b, b, L):
            state = 5
        elif action(Z, Z, L):
            state = 5

    elif state == 5:
        if action(Z, Z, R):
            state = 8
        elif action(b, Y, R):
            state = 6

    elif state == 6:
        if action(Z, Z, R) or action(b, b, R):
            state = 6
        elif action(a, Z, L):
            state = 7

    elif state == 7:
        if action(b, b, L) or action(Z, Z, L):
            state = 7
        elif action(Y, Y, R):
            state = 5

    elif state == 8:
        if action(Z, Z, L):
            state = 8
        elif action(B, B, L):
            state = 9
    else:
        accept = True 


if accept:
    print("Accept the string")
else:
    print("Reject the string")
