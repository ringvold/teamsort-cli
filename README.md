CSGO Teamsorting
================

This project uses Minizinc and the COIN-BC solver to create even teams from a list of players with ranks.

This project is created to be used to create teams for CSGO tournaments but could probably be used in other context with some ajustments.

For our use the teams generated often needs some manual work to get optimal teams, but is a great tool to get a good starting point to work from. 

# Docker

Build the `Dockerfile`
```sh
docker build -t teamsort .
```

then run it

```
docker run -v $(pwd)/input:/input --rm teamsort /input/example.txt
```

# Installation

1. Nodejs and npm/yarn
2. Minizinc and solver  
    Install COIN-OR CBC (https://www.minizinc.org/doc-2.4.2/en/installation_detailed.html) and Minizinc (https://www.minizinc.org/doc-2.4.2/en/installation.html). Note: "MiniZinc contains a built-in interface to CBC, so in order to use it you have to install CBC _before_ compiling MiniZinc."
3. From cli directory run `npm install` and `npm build`  

# Usage

Run `cli/build/teamsorting.js sort <filename>`.


# Future plans

[] Send the result to other tools for further work on the teams (Trello).
