import CLIMiniZinc from 'minizinc/build/CLIMiniZinc';

const m = new CLIMiniZinc();

const model = `set of int: Rank = 1..18;
array[Rank] of int: rankPower =
   [ 8
   , 9
   , 10
   , 11
   , 12
   , 13
   , 14
   , 15
   , 16
   , 17
   , 18
   , 19
   , 20
   , 21
   , 22
   , 23
   , 24
   , 25
   ];
 
% Avoid recursive definition between noOfPlayers and rank
% by defining the inputs in an array of unspecified size.
array[int] of Rank: playerRanks;
array[Players] of string: players;
int: tonjeIndex;
int: haraldIndex;
int: clementsIndex;
int: chickenIndex;
    
int: maxPlayersPerTeam = 5;
int: minPlayersPerTeam = 4;
int: noOfTeams = ceil(noOfPlayers / maxPlayersPerTeam);
int: noOfPlayers = length(playerRanks);
set of int: Players = 1..noOfPlayers;
set of int: Teams = 1..noOfTeams;
array[Players] of int: rank = playerRanks;
array[Players] of var 1..noOfTeams: team; 



array[Teams] of var int: score;

set of int: TeamSize = 4..5;
array[Teams] of var TeamSize: teamSize;

constraint forall(t in Teams) (
     teamSize[t] = sum([team[p] == t | p in Players])
  );

%  same number of players per team
constraint forall(t in Teams) (
     maxPlayersPerTeam >= sum([team[p] == t | p in Players])
  );

% Tonje og Harald på samme lag
constraint (
     team[tonjeIndex] == team[haraldIndex]
  );

    
%  sum up the ELO numbers per team
constraint forall(t in Teams) (
     score[t] == sum([if team[p] == t then rank[p] else 0 endif | p in Players])
  );
  
%  enforce sorted sums to break symmetries
%  and avoid minimum/maximum predicates
constraint forall(t1 in Teams, t2 in Teams where t1 < t2) (
    score[t1] <= score[t2]
  );   
  
% Symmetry breaking constraint => last team - first team = greates diff
solve minimize score[noOfTeams] - score[1];
`;

m.solve({model, solver: "cbc"}, {playerRanks: [6,3,16,11,16,16,13,13,12,12,3,1,8,10,8,4,7,8,4,1,6,7,13,1], 
	players: ["Darkness  sem 6","Samuelps  s3. 3","Chicken lem 16","Dr.eggman/eask64  mg1.  11","Ditlesen  lem 16","wolverin  lem 16","Crimsonfukrr  mge 13","Nazario mge 13","kaptein snabeltann  mg2.  12","Le pipe mg2.  12","bna-cooky s3. 3","ClemensBenz[500E] s1. 1","Buððah  gn2.  8","McDuckian gnm 10","Madde gn2.  8","Falchy  s4. 4","KSI gn1.  7","l0lpalme  gn2.  8","Youngfafo s4. 4","antorn3dthe7th  s1. 1","IQStrom sem 6","Shabby  gn1.  7","LuftGraven  mg2.  12","SchousKanser  s1. 1"],
	tonjeIndex: 15, haraldIndex: 18, chickenIndex: 0, clementsIndex:0}
	).then((result) => {
  console.log(result);
});
