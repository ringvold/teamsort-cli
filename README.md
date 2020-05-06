CSGO Teamsorting
================

This project uses [Minizinc](https://www.minizinc.org/) and the [COIN-OR CBC solver](https://github.com/coin-or/Cbc)  to create even teams from a list of players with ranks.

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

1. Nodejs and yarn
2. Minizinc and solver  
    Install COIN-OR CBC (https://www.minizinc.org/doc-2.4.2/en/installation_detailed.html) and Minizinc (https://www.minizinc.org/doc-2.4.2/en/installation.html). Note: "MiniZinc contains a built-in interface to CBC, so in order to use it you have to install CBC _before_ compiling MiniZinc."
3. From cli directory run `npm install` and `npm build`  

# Usage

Install manually og use the provided dockerfile. See seperate sections for these.

To run the command from manuall install: `./cli/build/teamsort`. Run without any parameters for usage information.

The CLI has two different options for use. One for terminal output and one which additionally post the result to a trello board. A file with a list of players with ranks is required in both of them.

## Input file

The input file need to have a player per line where player name and rank seperated by tab (`\t`) is the minimum requirement. 
You can also provide an alias for the rank (for output readability) and specify which team you want a given player (or set of players) to end up in.

Full format is: player name, rank alias, team, rank (`player_a	rank_name_1	1	1`).

See [input/example.txt] for an example.

## Trello integration

To use the trello integration you need to get an API key and token: https://developer.atlassian.com/cloud/trello/guides/rest-api/api-introduction/#authentication-and-authorization

These can then be set as environment variables, through `.env` file or as parameters in the cli.

# Future plans
- [ ] Player ID as an input option (Steam ID for integration with Get5/G5API)
- [ ] Other input formats
- [ ] Send the result to [G5API](https://github.com/PhlexPlexico/G5API)
- [ ] Read teams out of trello to send to other integration (G5API)

