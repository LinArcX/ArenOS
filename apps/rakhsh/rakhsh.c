#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/wait.h>
#include <termios.h>

#define RAKHSH "Rakhsh"

struct termios orig_termios;

void disableRawMode() 
{
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios);
}

void enableRawMode() 
{
  tcgetattr(STDIN_FILENO, &orig_termios);
  atexit(disableRawMode);

  struct termios raw = orig_termios;
  raw.c_lflag &= ~(ECHO | ICANON | ISIG);
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);


  //tcgetattr(STDIN_FILENO, &orig_termios);
  //atexit(disableRawMode);

  //struct termios raw = orig_termios;
  //raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
  //raw.c_oflag &= ~(OPOST);
  //raw.c_cflag |= (CS8);
  //raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);

  //// Set the terminal to non-blocking mode
  //raw.c_cc[VMIN] = 0;
  //raw.c_cc[VTIME] = 0;

  //tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);

  //// Set the terminal to non-blocking mode using fcntl
  //int flags = fcntl(STDIN_FILENO, F_GETFL);
  //flags |= O_NONBLOCK;
  //fcntl(STDIN_FILENO, F_SETFL, flags);

  ////fcntl(STDIN_FILENO, F_SETFL, O_NONBLOCK);
}

//char readKey() 
//{
//  char c;
//  int nread = read(STDIN_FILENO, &c, 1);
//  if (nread == -1) 
//  {
//    // Handle non-blocking read error
//    return '\0';
//  }
//  return (nread == 1) ? c : '\0';
//}

void 
processConfigurations()
{

}

char*
readLine()
{
  int16_t initalBufferSize = 1024;
  char *buffer = malloc(sizeof(char) * initalBufferSize);
  if (!buffer) 
  {
    fprintf(stderr, "%s: allocation error\n", RAKHSH);
  }

  int c;
  int position = 0;
  int currentBufferSize = initalBufferSize;

  while (1) 
  {
    // Read a character
    c = getchar();

    // If we hit EOF, replace it with a null character and return.
    if (c == EOF || c == '\n') 
    {
      buffer[position] = '\0';
      return buffer;
    } 
    else
    {
      buffer[position] = c;
    }
    position++;

    // If we have exceeded the buffer, reallocate.
    if (position >= currentBufferSize) 
    {
      currentBufferSize += initalBufferSize;
      buffer = realloc(buffer, currentBufferSize);
      if (!buffer) 
      {
        fprintf(stderr, "%s: allocation error\n", RAKHSH);
      }
    }
  }
}

char**
splitLine(char* line)
{
  int initialBufferSize = 64;
  char **tokens = malloc(initialBufferSize * sizeof(char*));

  if (!tokens) 
  {
    fprintf(stderr, "%s: allocation error\n", RAKHSH);
  }

  int position = 0;
  int currentBufferSize = initialBufferSize;

  char* tokenDelimiter = " \t\r\n\a";
  char *token = strtok(line, tokenDelimiter);
  while (NULL != token)
  {
    tokens[position] = token;
    position++;

    if (position >= currentBufferSize)
    {
      currentBufferSize += initialBufferSize;
      tokens = realloc(tokens, currentBufferSize * sizeof(char*));
      if (!tokens)
      {
        fprintf(stderr, "%s: allocation error\n", RAKHSH);
      }
    }

    token = strtok(NULL, tokenDelimiter);
  }
  tokens[position] = NULL;
  return tokens;
}

char *builtins[] = {
  "cd",
  "help",
  "exit"
};

int
builtinsCount() 
{
  return sizeof(builtins) / sizeof(char *);
}

int 
rakhsh_cd(char **args)
{
  if (NULL == args[1]) 
  {
    fprintf(stderr, "%s: expected argument to \"cd\"\n", RAKHSH);
  }
  else
  {
    if (0 != chdir(args[1]))
    {
      perror(RAKHSH);
    }
  }
  return 1;
}

int
rakhsh_help(char **args)
{
  int i;
  printf("#=------------------------------------------------------------------------=#\n");
  printf("#=-- Rakhsh is a brave and faithful steed of the preeminent hero Rostam --=#\n");
  printf("#=------------------------------------------------------------------------=#\n\n");
  printf("Available commands:\n");

  for (i = 0; i < builtinsCount(); i++) 
  {
    printf("  %s\n", builtins[i]);
  }
  return 1;
}

int 
rakhsh_exit(char **args)
{
  return 0;
}

int (*builtin_func[]) (char **) = {
  &rakhsh_cd,
  &rakhsh_help,
  &rakhsh_exit
};

int
launch(char **args)
{
  int status;

  pid_t pid = fork();
  if (0 == pid)
  {
    // Child process
    if (execvp(args[0], args) == -1) 
    {
      perror(RAKHSH);
    }
    exit(EXIT_FAILURE);
  } 
  else if (pid < 0) 
  {
    // Error forking
    perror(RAKHSH);
    exit(EXIT_FAILURE);
  }
  else
  {
    // The parent process enters a loop where it repeatedly calls waitpid to wait for the child process to change its state.
    // The loop continues until the child process either exits normally or is terminated by a signal.
    // This mechanism ensures that the parent process does not proceed until the child process has completed its execution.
    do {
      pid_t wpid = waitpid(pid, &status, WUNTRACED);
    } while (!WIFEXITED(status) && !WIFSIGNALED(status));
  }
  return 1;
}

int
execute(char** args)
{
  int i;

  if (NULL == args[0]) 
  {
    // An empty command was entered.
    return 1;
  }

  for (i = 0; i < builtinsCount(); i++) 
  {
    if (strcmp(args[0], builtins[i]) == 0) 
    {
      return (*builtin_func[i])(args);
    }
  }

  return launch(args);
}

#include <ctype.h>
void
processCommands(void)
{
  enableRawMode();
  char *line = NULL;
  char **args = NULL;
  int status = 1;

  char c;
  while (read(STDIN_FILENO, &c, 1) == 1 && c != 'q') 
  {
    if (iscntrl(c)) 
    {
      if (c == 12)
      { 
        // Ctrl+l (Clear screen)
        printf("\e[1;1H\e[2J");
        continue;
      }
      else if (c == 21)
      { 
        // Ctrl+l (Clear screen)
        printf("\033[K");
        continue;
      }
      else
      {
        printf("%d\n", c);
      }
    } else {
      printf("%d ('%c')\n", c, c);
    }
  }

  //while (status)
  //{
    //printf("Rakhsh → ");
    //char c = readKey();


    //while (read(STDIN_FILENO, &c, 1) == 1)
    //{
    //  else
    //  {
    //    // Read the rest of the line
    //    //ungetc(c, stdin);
    //    //line = readLine();
    //    //args = splitLine(line);
    //    //status = execute(args);

    //    //free(line);
    //    //line = NULL;
    //    //free(args);
    //    //args = NULL;
    //  }
    //}


  //} 

  disableRawMode();
}

void
shutdown()
{

}

int
main(int argc, char **argv)
{
  // clear the screen at startup
  printf("\e[1;1H\e[2J"); 

  processConfigurations();
  processCommands();
  shutdown();
  return EXIT_SUCCESS;
}
