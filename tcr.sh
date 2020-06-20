# Test && Commit || Revert
inInterrupt=false
filter=""
environment="C#"

function SetupTcrWatch() {
    while true; do
        if [[ "$environment" == "C#" ]]
          then
            inotifywait -qq -r -e modify --exclude cs~ "$PWD"
          else
            inotifywait -qq -r -e modify --exclude ts~ "$PWD"
        fi

        if [[ "$inInterrupt" == false ]]; then
            wmctrl -l
            reset
            if [[ "$environment" == "C#" ]]
              then
                tcr-script.sh $filter
              elif [[ "$input" == "Angular" ]]
              then
                echo "Run tcr for angular"
              else
                echo "No tcr environment set"
            fi
        else
            inInterrupt=false
        fi
    done
}

function SanitizeOrAskForInput() {
  [[ "$1" == "" ]] && echo "$2" && read -r input || input="$1"
  input="$(sed -e 's/^"//' -e 's/"$//' <<<"$input")"
  return 0
}

function CommitWorkInProgress() {
    SanitizeOrAskForInput "$1" "Please type your commit message:"

    commitCount=$(git log --oneline origin/master..HEAD | grep -c WIP | tr -d '[:space:]')

    git reset --soft HEAD~"$commitCount"

    git commit -m "$input"
}

function SetTestFilter() {
    SanitizeOrAskForInput "$1" "Please the class name of your tests: " && filter=$input
}

function SetupEnvironment() {
    SanitizeOrAskForInput "$1" "Please indicate your environment (C# or Angular):"

    if [[ "$input" == "C#" ]]
      then
        environment="$input"
        echo "C# chosen"
      elif [[ "$input" == "Angular" ]]
      then
        environment="$input"
        echo "Angular chosen"
      else
        echo "Invalid choice. Sticking to current environment: $environment"
        return 1
    fi

    SetupTcrWatch
}

function WriteAvailableCommands() {
    echo "   help                    Prints the help information and continues TCR"
    echo "   stop:                   Stops the TCR watcher"
    echo "   commit [ <message> ]    Finizales the work in progress in a commit with"
    echo "                           the specified message and continues TCR"
    echo "   continue                Continue the TCR watcher"
    echo "   filter                  Specify an inclusive filter for the tests to use"
    echo "   setup                   Setup the environment (C# or Angular) for TCR"
}

function WriteInvalidInputMessage() {
    echo "I don't understand. These are the commands I listen to:"
    WriteAvailableCommands
}

function WriteHelpInformation() {
    echo "These are the commands I listen to:"
    WriteAvailableCommands
}

function CheckValidInput() {
  [[ "$command" == "$1" ]] && validInput=true && return 0 || return 1
}

function OnInturrupt() {
    reset
    echo "Pausing TCR. How can I help you?"

    inInterrupt=true
    validInput=false

    while ! $validInput; do
        read -r command arg0
        CheckValidInput "help" && WriteAvailableCommands
        CheckValidInput "stop" && exit
        CheckValidInput "commit" && CommitWorkInProgress "$arg0"
        CheckValidInput "filter" && SetTestFilter "$arg0"
        CheckValidInput "setup" && SetupEnvironment "$arg0"
        CheckValidInput "continue"
        [[ "$validInput" == false ]] && WriteInvalidInputMessage
    done

}

trap "OnInturrupt" SIGINT

SetupTcrWatch
