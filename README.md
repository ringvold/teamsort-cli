CSGO Teamsorting
================

Minizinc project to sort a list of CSGO ranked players into even teams. The CSGO ranks are converted to number and are represened as 1-18.

The script is simple for now and needs to arrays. One is the list of ranks and the other is the list on corresponding player names. The script assumes the to lists are in the same order. IE, the first number in the rank list is the rank of the first name in the names list.

This project is created to be used to create teams for CSGO tournaments but could probably be used in other context with minor ajustments.

For our use the script need some manual work to get optimal teams, but is a great tool to get a good starting point to work from. 

# Usage

Open in Minizinc IDE and populate data.dzn with you player arrays, one for the ranks and one for the names.

The COIN-BC solver seems to be the most efficient of the included solvers.

# Future plans

- Make it easier to give input to the solver and display the results. This is planned for to be done by python scripts as there are existing integrations for minizinc in python (https://minizinc-python.readthedocs.io or https://github.com/paolodragone/PyMzn).

- Send the result to other tools for further work on the teams (Trello).