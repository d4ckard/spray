#include "test_utils.h"

#include "../src/breakpoints.h"
#include "../src/debugger.h"

TEST(breakpoints_work) {
  Debugger dbg;
  char *prog_argv[] = { SIMPLE_64BIT_BIN, NULL };
  assert_int(setup_debugger(prog_argv[0], prog_argv, &dbg), ==, 0);

  x86_addr bp_addr1 = { 0x00401122 };

  enable_breakpoint(dbg.breakpoints, bp_addr1);
  assert_true(lookup_breakpoint(dbg.breakpoints, bp_addr1));

  disable_breakpoint(dbg.breakpoints, bp_addr1);
  assert_false(lookup_breakpoint(dbg.breakpoints, bp_addr1));

  free_debugger(dbg);
  
  return MUNIT_OK;
}

extern SprayResult check_file_line(const char *file_line);

TEST(file_line_check_works) {
  SprayResult res = check_file_line("this/is/a/file:2578");
  assert_int(res, ==, SP_OK);

  res = check_file_line("this/is/a/filename/without/a/line");
  assert_int(res, ==, SP_ERR);

  res = check_file_line("710985");
  assert_int(res, ==, SP_ERR);

  res = check_file_line("src/blah/test.c74");
  assert_int(res, ==, SP_ERR);

  return MUNIT_OK;
}

extern SprayResult check_function_name(const char *func_name);

TEST(function_name_check_works) {
  SprayResult res = check_function_name("function_name_check_works1203");
  assert_int(res, ==,  SP_OK);

  res = check_function_name("785019blah_function");  // Starts with numbers.
  assert_int(res, ==, SP_ERR);

  res = check_function_name("check-function-name");  // Kebab case.
  assert_int(res, ==, SP_ERR);

  res = check_function_name("check>function!>name");  // Other symbols.
  assert_int(res, ==, SP_ERR);

  return MUNIT_OK;
}


MunitTest debugger_tests[] = {
  REG_TEST(breakpoints_work),
  REG_TEST(file_line_check_works),
  REG_TEST(function_name_check_works),
  { NULL, NULL, NULL, NULL, MUNIT_TEST_OPTION_NONE, NULL }  
};
