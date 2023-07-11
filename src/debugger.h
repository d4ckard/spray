#pragma once

#ifndef _SPRAY_DEBUGGER_H_
#define _SPRAY_DEBUGGER_H_

// Required to use `sigabbrev_np`
#define _GNU_SOURCE

#include <stdlib.h>

#include "breakpoints.h"
#include "spray_elf.h"
#include "spray_dwarf.h"
#include "source_files.h"
#include "history.h"

typedef struct {
  const char *prog_name;     /* Tracee program name. */
  pid_t pid;                 /* Tracee pid. */
  Breakpoints *breakpoints;  /* Breakpoints. */
  ElfFile elf;               /* Tracee ELF information. */
  x86_addr load_address;     /* Load address. Set for PIEs, 0 otherwise. */
  Dwarf_Debug dwarf;         /* Libdwarf debug information. */
  SourceFiles *files;        /* Cache of program source files read. */
  History history;           /* Command history of recent commands. */
} Debugger;

// Setup a debugger. This forks the child process.
// `store` is only modified on success. The values
// it initially has are never read.
// This launches the debuggee process and immediately stops it.
int setup_debugger(const char *prog_name, char *prog_argv[], Debugger *store);

// Run a debugger. Starts at the beginning of
// the `main` function.
void run_debugger(Debugger dbg);

// Free memory allocated by the debugger.
// Called by `run_debugger`.
void free_debugger(Debugger dbg);

#endif  // _SPRAY_DEBUGGER_H_
