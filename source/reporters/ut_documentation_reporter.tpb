create or replace type body ut_documentation_reporter is
  /*
  utPLSQL - Version X.X.X.X
  Copyright 2016 - 2017 utPLSQL Project

  Licensed under the Apache License, Version 2.0 (the "License"):
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  */

  constructor function ut_documentation_reporter(self in out nocopy ut_documentation_reporter) return self as result is
  begin
    self.init($$plsql_unit);
    self.lvl                       := 0;
    self.failed_test_running_count := 0;
    return;
  end;

  member function tab(self in ut_documentation_reporter) return varchar2 is
  begin
    return rpad(' ', self.lvl * 2);
  end;

  member function tab(self in ut_documentation_reporter, a_text varchar2) return varchar2 is
  begin
    if rtrim(a_text) is not null then
      return rtrim(tab||replace(a_text,chr(10), chr(10)||tab()));
    else
      return a_text;
    end if;
  end tab;

  member function tab(self in ut_documentation_reporter, a_lines ut_varchar2_list) return ut_varchar2_list is
    l_lines ut_varchar2_list;
  begin
    if a_lines is not null then
      l_lines := a_lines;
      for i in 1 .. l_lines.count loop
        l_lines(i) := tab(l_lines(i));
      end loop;
    end if;
    return l_lines;
  end tab;

  overriding member procedure print_lines(self in out nocopy ut_documentation_reporter, a_lines ut_varchar2_list) is
    l_lines ut_varchar2_list := a_lines;
  begin
    if l_lines is not null then
      for i in 1 .. l_lines.count loop
        l_lines(i) := tab(l_lines(i));
      end loop;
    end if;
   (self as ut_output_reporter_base).print_lines(l_lines);
  end;

  overriding member procedure print_text(self in out nocopy ut_documentation_reporter, a_text varchar2) is
  begin
   (self as ut_output_reporter_base).print_text(tab(a_text));
  end;

  overriding member procedure before_calling_suite(self in out nocopy ut_documentation_reporter, a_suite ut_logical_suite) as
  begin
    self.print_text(coalesce(a_suite.description, a_suite.name));
    lvl := lvl + 1;
  end;

  overriding member procedure after_calling_test(self in out nocopy ut_documentation_reporter, a_test ut_test) as
    l_message varchar2(4000);

  begin
    l_message := coalesce(a_test.description, a_test.name)||' ['||round(a_test.execution_time,3)||' sec]';
    --if test failed, then add it to the failures list, print failure with number
    if a_test.result = ut_utils.tr_disabled then
      self.print_yellow_text(l_message || ' (IGNORED)');
    elsif a_test.result = ut_utils.tr_success then
      self.print_green_text(l_message);
    elsif a_test.result > ut_utils.tr_success then
      failed_test_running_count := failed_test_running_count + 1;
      self.print_red_text(l_message || ' (FAILED - ' || failed_test_running_count || ')');
    end if;

    -- reproduce the output from before/after procedures and the test
    self.print_clob(a_test.get_serveroutputs);
  end;

  overriding member procedure after_calling_before_all(self in out nocopy ut_documentation_reporter, a_suite in ut_logical_suite) is
  begin
    self.print_clob(treat(a_suite as ut_suite).before_all.serveroutput);
  end;

  overriding member procedure after_calling_after_all(self in out nocopy ut_documentation_reporter, a_suite in ut_logical_suite) is
  begin
    self.print_clob(treat(a_suite as ut_suite).after_all.serveroutput);
  end;

  overriding member procedure after_calling_suite(self in out nocopy ut_documentation_reporter, a_suite ut_logical_suite) as
  begin
    lvl := lvl - 1;
    if lvl = 0 then
      self.print_text(' ');
    end if;
  end;

  overriding member procedure after_calling_run(self in out nocopy ut_documentation_reporter, a_run in ut_run) as
    c_nl             varchar2(1) := chr(10);
    l_summary_text   varchar2(4000);
    l_warning_index pls_integer := 0;
    -- make all warning indexes uniformly indented
    c_warnings_lpad constant integer := length(to_char(a_run.results_count.warnings_count));

    function get_failure_for_expectation(a_expectation ut_expectation_result) return ut_varchar2_list is
      l_lines ut_varchar2_list;
    begin
      l_lines := a_expectation.get_result_lines();
      l_lines := self.red(l_lines);
      ut_utils.append(l_lines, self.cyan(a_expectation.caller_info));
      ut_utils.append(l_lines, ' ');
      return l_lines;
    end;

    procedure print_failures_for_test(a_test ut_test, a_failure_no in out nocopy integer) is
      l_failures ut_varchar2_list := ut_varchar2_list();
    begin
      if a_test.result > ut_utils.tr_success then
        a_failure_no := a_failure_no + 1;
        ut_utils.append( l_failures, lpad(a_failure_no, length(failed_test_running_count) + 2, ' ') || ') '|| nvl(a_test.name, a_test.item.form_name));
        self.lvl := self.lvl + 3;

        ut_utils.append(l_failures, tab(self.red(a_test.get_error_stack_traces())));

        for j in 1 .. a_test.results.count loop
          if a_test.results(j).status > ut_utils.tr_success then
            ut_utils.append(l_failures, tab(get_failure_for_expectation(a_test.results(j))));
          end if;
        end loop;
        self.lvl := self.lvl - 3;
        self.print_lines(l_failures);
      end if;
    end;

    procedure print_failures_from_suite(a_suite ut_logical_suite, a_failure_no in out nocopy integer) is
    begin
      for i in 1 .. a_suite.items.count loop
        if a_suite.items(i) is of(ut_logical_suite) then
          print_failures_from_suite(treat(a_suite.items(i) as ut_logical_suite), a_failure_no);
        elsif a_suite.items(i) is of(ut_test) then
          print_failures_for_test(treat(a_suite.items(i) as ut_test), a_failure_no);
        end if;
      end loop;
    end;

    procedure print_failures_details(a_run in ut_run) is
      l_failure_no integer := 0;
    begin
      if a_run.results_count.failure_count > 0 or a_run.results_count.errored_count > 0 then

        self.print_text('Failures:');
        self.print_text(' ');
        for i in 1 .. a_run.items.count loop
          print_failures_from_suite(treat(a_run.items(i) as ut_logical_suite), l_failure_no);
        end loop;
      end if;
    end;

    procedure print_item_warnings(a_item in ut_suite_item) is
      l_items ut_suite_items;
      l_warnings ut_varchar2_list;
    begin
      if a_item is of (ut_logical_suite) then
        l_items := treat(a_item as ut_logical_suite).items;
        for i in 1 .. l_items.count loop
          if l_items(i) is of(ut_suite_item) then
            print_item_warnings(l_items(i));
          end if;
        end loop;
      end if;

      if a_item.warnings is not null and a_item.warnings.count > 0 then
        l_warnings := a_item.warnings;
        self.lvl := self.lvl + 3;
        for i in 1 .. l_warnings.count loop
          l_warning_index := l_warning_index + 1;
          l_warnings(i) :=
            '  ' || lpad(l_warning_index, c_warnings_lpad) || ') ' || a_item.path ||c_nl
            ||tab(self.red(l_warnings(i)));
        end loop;
        self.lvl := self.lvl - 3;
        ut_utils.append(l_warnings, ' ');
        self.print_lines(l_warnings);
      end if;
    end;

    procedure print_warnings(a_run in ut_run) is
    begin
      if a_run.results_count.warnings_count > 0 then
        self.print_text(' '||c_nl||'Warnings:'||c_nl||' ');
        for i in 1 .. a_run.items.count loop
          print_item_warnings(treat(a_run.items(i) as ut_suite_item));
        end loop;
      end if;
    end;

  begin
    print_failures_details(a_run);
    print_warnings(a_run);
    l_summary_text :=
      a_run.results_count.total_count || ' tests, '
      || a_run.results_count.failure_count || ' failed, ' || a_run.results_count.errored_count || ' errored, '
      || a_run.results_count.disabled_count ||' disabled, ' || a_run.results_count.warnings_count || ' warning(s)'||c_nl
      ||' ';
    if a_run.results_count.failure_count + a_run.results_count.errored_count + a_run.results_count.warnings_count > 0 then
      l_summary_text := self.red(l_summary_text);
    else
      l_summary_text := self.green(l_summary_text);
    end if;
    self.print_text(
      'Finished in ' || a_run.execution_time || ' seconds'||c_nl
      ||l_summary_text
    );
  end;

end;
/
