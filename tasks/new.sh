# # Creating a new project
#
# This task is still very simple, although it helps a lot. It creates new
# bang-based projects and generates an executable file with the project's name.
#
# The task takes only one argument which can be the project name or a path. In
# the case only the name is given, the path used is the current directory.
#
# # Examples:
#
#     $ bang new my_project
#     # Creates:
#     #   - ./my_project
#     #   |-- modules/.gitkeep
#     #   |-- tasks/.gitkeep
#     #   |-- tests/.gitkeep
#     #   |-- my_project
#
#     $ bang new projects/task_new
#     # Creates:
#     #   - ./projects/
#     #   |-- task_new/
#     #     |-- modules/.gitkeep
#     #     |-- tasks/.gitkeep
#     #     |-- tests/.gitkeep
#     #     |-- task_new
function btask.new.run () {
  local project="$1"
  if [ -n "$project" ]; then
    (
      cd "$(b.get bang.working_dir)"
      mkdir -p "$project"

      _create_module_path
      _create_tasks_path
      _create_tests_path
      _create_projections_file
      _create_make_file
      _create_exec_file
      _create_main_file
    )
  fi
}

function _create_module_path () {
  mkdir -p "$project/modules"
}

function _create_tasks_path () {
  mkdir -p "$project/tasks"
}

function _create_tests_path () {
  mkdir -p "$project/tests"
}

function _create_projections_file () {
  local project_name="$(basename "$project")"
  cat <<EOF >"$project/.projections.json"
{
  "${project_name}": {
    "type": "main"
  },

  "modules/*.sh": {
    "type": "modules",
    "skeleton": "modules"
  },

  "tasks/*.sh": {
    "type": "tasks",
    "skeleton": "tasks"
  },

  "tests/*.sh": {
    "type": "tests",
    "skeleton": "tests"
  }
}
EOF
}

function _create_exec_file () {
  local project_name="$(basename "$project")"
  cat <<EOF >"$project/exec"
#!/usr/bin/env bash
path=\$PWD
(
  cd \$(dirname \$(readlink -f \$(which $project_name)))
  bang run $project_name \$@
)
EOF
  chmod +x "$project/exec"
}

function _create_make_file () {
  local project_name="$(basename "$project")"
  cat <<EOF >"$project/Makefile"
PROJECT = $project_name

prefix ?= /usr/local

# If the first argument is "run"...
ifeq (run,\$(firstword \$(MAKECMDGOALS)))
  # use the rest as arguments for "run"
  RUN_ARGS := \$(wordlist 2,\$(words \$(MAKECMDGOALS)),\$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  \$(eval \$(RUN_ARGS):;@:)
endif

prog: # ...
   # ...

.PHONY: run
run : prog
	@bang run \$(PROJECT) \$(RUN_ARGS)
test:
	bang test

install: install-\$(PROJECT)

install-\$(PROJECT):
	-mkdir -p \$(prefix)/bin
	ln -s \`pwd\`/exec \$(prefix)/bin/\$(PROJECT)

clean:
	@-rm -rf \$(prefix)/bin/\$(PROJECT)
EOF
}

function _create_main_file () {
  local project_name="$(basename "$project")"
  exec >> "$project/$project_name"

  echo
  echo '[ -n "$1" ] && b.task.run "$@"'

}


