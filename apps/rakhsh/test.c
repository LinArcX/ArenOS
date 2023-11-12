#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_COMMANDS 5
#define MAX_COMMAND_LENGTH 20

// List of commands for demonstration purposes
char* commands[MAX_COMMANDS] = {"ls", "cd", "pwd", "cp", "mv"};

// Function to perform tab completion
void tabCompletion(char* input) {
    int i;
    int matches = 0;
    char* partial = NULL;

    // Check for partial match
    for (i = 0; i < MAX_COMMANDS; ++i) {
        if (strncmp(commands[i], input, strlen(input)) == 0) {
            matches++;
            partial = commands[i];
        }
    }

    // Display suggestions or complete the input
    if (matches == 1) {
        printf("\n%s", partial);
        fflush(stdout);
        strcpy(input, partial);
    } else if (matches > 1) {
        printf("\nSuggestions:\n");
        for (i = 0; i < MAX_COMMANDS; ++i) {
            if (strncmp(commands[i], input, strlen(input)) == 0) {
                printf("%s\n", commands[i]);
            }
        }
        printf("\n");
    }
}

int main() {
    char input[MAX_COMMAND_LENGTH];

    while (1) {
        printf("MyShell> ");
        fgets(input, sizeof(input), stdin);

        // Remove newline character from input
        input[strcspn(input, "\n")] = '\0';

        // Perform tab completion when Tab is pressed
        if (input[0] == '\t') {
            tabCompletion(&input[1]);
            continue;
        }

        // Process the user's input (for demonstration, just print the input)
        printf("You entered: %s\n", input);
    }

    return 0;
}
