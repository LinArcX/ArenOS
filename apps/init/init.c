#include <sys/types.h>
#include <sys/wait.h>

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define TIMEO	30
#define LEN(x)	(sizeof (x) / sizeof *(x))

static void sigreap(void);
static void sigreboot(void);
static void sigpoweroff(void);
static void login(void);
static void spawn(char *const []);

static struct {
	int sig;
	void (*handler)(void);
} sigmap[] = {
	{ SIGUSR1, sigpoweroff },
	{ SIGCHLD, sigreap     },
	{ SIGALRM, sigreap     },
	{ SIGINT,  sigreboot   },
};

static char *const initcmd[]     = { "/etc/init.rc", NULL };
static char *const logincmd[]    = { "/bin/login", NULL, NULL };
static char *const rebootcmd[]   = { "/etc/shutdown.rc", "reboot", NULL };
static char *const poweroffcmd[] = { "/etc/shutdown.rc", "poweroff", NULL };



static sigset_t set;

int
main(void)
{
  printf("\e[1;1H\e[2J");  

  int sig;
	size_t i;

	if (getpid() != 1)
  {
		return EXIT_FAILURE;
  }
	chdir("/");

  // Blocks all signals to prevent the process from receiving any signals before initialization is complete. 
	sigfillset(&set);
	sigprocmask(SIG_BLOCK, &set, NULL);

  // Spawns an initial set of processes specified in the rcinitcmd array
	spawn(initcmd);

	while (1) 
  {
		alarm(TIMEO);
		sigwait(&set, &sig);

		for (i = 0; i < LEN(sigmap); i++) 
    {
			if (sigmap[i].sig == sig) 
      {
				sigmap[i].handler();
				break;
			}
		}
	}

	// not reachable
	return EXIT_SUCCESS;
}

static void
spawn(char *const argv[])
{
	switch (fork()) {
	case 0:
		sigprocmask(SIG_UNBLOCK, &set, NULL);
		setsid();
		execvp(argv[0], argv);
		perror("execvp");
		_exit(1);
	case -1:
		perror("fork");
	}
}

// collecting status information about terminated child processes
static void
sigreap(void)
{
  char *shlvl_value = getenv("SHLVL");
  if (shlvl_value != NULL) {
    int shl_level = atoi(shlvl_value);
    if(shl_level <= 1)
    {
      login();
    }
  }

  // wait for all PIDs to die
	while (waitpid(-1, NULL, WNOHANG) > 0)
		;
	alarm(TIMEO);
}
static void
sigreboot(void)
{
	spawn(rebootcmd);
}

static void
sigpoweroff(void)
{
	spawn(poweroffcmd);
}

static void
login(void)
{	
  spawn(logincmd);
}
