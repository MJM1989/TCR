filter=$1

RED="tput setaf 1"
GREEN="tput setaf 2"
YELLOW="tput setaf 3"
MAGENTA="tput setaf 5"
DEFAULT="tput sgr0"

function Build() {
    echo "$($MAGENTA)==== Build ====$($DEFAULT)"
    dotnet build --nologo -v q
}

function Test() {
    echo ""
    echo "$($YELLOW)==== Test ====$($DEFAULT)"
    echo ""

    if [[ "$filter" == "" ]]
    then
      dotnet test --no-build --nologo
    else
      dotnet test --no-build --nologo --filter FullyQualifiedName~"${filter}"
    fi
}

function Commit() {
    echo ""
    echo "$($GREEN)==== Commit ====$($DEFAULT)"
    echo ""
    git add .
    git commit -m "WIP"
    return 0
}

function Amend() {
    echo "$($GREEN)==== Commit (amend) ====$($DEFAULT)"
    echo ""
    git commit -am "WIP" --amend --allow-empty
}

function Checkout() {
    echo "$($RED)==== Revert (implementation) ====$($DEFAULT)"
    echo ""
    git checkout Kata/
}

function Revert() {
    echo "$($RED)==== Revert ====$($DEFAULT)"
    echo ""
    git reset --hard
}

function AmendOrCommit() {
    [[ $(git log -1 --pretty=format:%B) == WIP ]] && Amend || Commit
}

function TestCommitCheckout() {
    (Test && AmendOrCommit) || Checkout
}

Build && Test && Commit || Revert
