# $language = "python"
# $interface = "1.0"

# This script demonstrates how to open a text file and read it line by
# line to a server.


def main():
    crt.Screen.Synchronous = True
    # Note: A IOError exception will be generated if 'input.txt' doesn't exist.
    #
    for line in open("c:\\temp\\input.txt", "r"):
        # Send the line with an appended CR
        #
        crt.Screen.Send(line + '\r')

        # Wait for my prompt before sending the next line
        #
        crt.Screen.WaitForString("prompt$")

    crt.Screen.Synchronous = False


main()