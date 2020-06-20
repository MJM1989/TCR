# Test && Commit || Revert
inInterrupt=false
filter=""

function SetupTcrWatch() {
    while true; do
        inotifywait -qq -r -e modify --exclude cs~ $PWD

        if [[ "$inInterrupt" == false ]]; then
	          wmctrl -l
            reset
            tcr-script.sh $filter
        else
            inInterrupt=false
        fi
    done
}

function CommitWorkInProgress() {
    [[ "$1" == "" ]] && echo "Please type your commit message: " && read -r message || message="$1"
    message=$(sed -e 's/^"//' -e 's/"$//' <<<"$message")

    commitCount=$(git log --oneline origin/master..HEAD | grep WIP | wc -l | tr -d '[:space:]')

    git reset --soft HEAD~"$commitCount"

    git commit -m $"$message"
}

function SetTestFilter() {
    [[ "$1" == "" ]] && echo "Please the class name of your tests: " && read -r filter || filter="$1"
    filter=$(sed -e 's/^"//' -e 's/"$//' <<<"$filter")
}

function WriteAvailableCommands() {
    echo "   help                    Prints the help information and continues TCR"
    echo "   stop:                   Stops the TCR watcher"
    echo "   commit [ <message> ]    Finizales the work in progress in a commit with"
    echo "                           the specified message and continues TCR"
    echo "   continue                Continue the TCR watcher"
    echo "   filter                  Specify an inclusive filter for the tests to use"
}

function WriteInvalidInputMessage() {
    echo "I don't understand. These are the commands I listen to:"
    WriteAvailableCommands
}

function WriteHelpInformation() {
    echo "These are the commands I listen to:"
    WriteAvailableCommands
}

function OnInturrupt() {
    reset
    echo "Pausing TCR. How can I help you?"

    inInterrupt=true
    validInput=false

    while ! $validInput; do
        read -r command arg0
        [[ "$command" == "help" ]] && validInput=true && WriteAvailableCommands
        [[ "$command" == "stop" ]] && validInput=true && exit
        [[ "$command" == "commit" ]] && validInput=true && CommitWorkInProgress "$arg0"
        [[ "$command" == "filter" ]] && validInput=true && SetTestFilter "$arg0"
        [[ "$command" == "continue" ]] && validInput=true
        [[ "$validInput" == false ]] && WriteInvalidInputMessage
    done

}

trap "OnInturrupt" SIGINT

SetupTcrWatch
