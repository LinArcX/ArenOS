#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>   

#define SIZE 100
#define ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]))

void getPassword(char password[])
{
  static struct termios oldt, newt;
  int i = 0;
  int c;

  /*saving the old settings of STDIN_FILENO and copy settings for resetting*/
  tcgetattr( STDIN_FILENO, &oldt);
  newt = oldt;

  /*setting the approriate bit in the termios struct*/
  newt.c_lflag &= ~(ECHO);          

  /*setting the new bits*/
  tcsetattr( STDIN_FILENO, TCSANOW, &newt);

  /*reading the password from the console*/
  while ((c = getchar())!= '\n' && c != EOF && i < SIZE){
      password[i++] = c;
  }
  password[i] = '\0';

  /*resetting our old STDIN_FILENO*/ 
  tcsetattr( STDIN_FILENO, TCSANOW, &oldt);
}

int
main(void)
{
  char line[300];
  FILE *file = fopen("/etc/shadow", "r");;

  if (NULL == file)
  {
    perror("Error opening file for reading");
    fclose(file);
    return EXIT_FAILURE;
  }
  char password[SIZE];
	char *shell = "/bin/sh";

ASK:
  memset(password, 0, ARRAY_SIZE(password));
  printf("password: ");
  getPassword(password);

  if (fgets(line, sizeof(line), file) == NULL)
  {
    if (strcmp(line, password) == 0)
    {
      // run the shell
	    execlp(shell, shell, "-l", NULL);
    }
    else
    {
      // re-ask for login info
      goto ASK;

    }
    return EXIT_SUCCESS;
  }
  else 
  {
    perror("Error reading line from file");
    fclose(file);
    return EXIT_FAILURE;
  }


  //// Open the file for writing
  //file = fopen("filename.txt", "a");  // "a" stands for append, use "w" to overwrite the file

  //if (file == NULL) {
  //    perror("Error opening file for writing");
  //    return 1;
  //}

  //// Write something to the file
  //fprintf(file, "This is a new line added to the file.\n");

  //// Close the file after writing
  //fclose(file);

  return 0;
}
