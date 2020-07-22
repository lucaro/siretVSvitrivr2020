using CSV, DataFrames, Combinatorics, Gadfly, Cairo

maxPointsPerTask = 100
maxPointsAtTaskEnd = 50
penaltyPerWrongSubmission = 10



submissions = CSV.read("submissions.csv")



taskGroups = groupby(submissions, :task)

dfs = DataFrame[]

for t in taskGroups
	teams = groupby(t, :team)
	taskDuration = 60000 * (occursin("Visual", t[1, :task]) ? 5 : 8)
	for submissions in teams
		score = 0
		if (any(submissions[:, :correctSegment]))
			firstCorrect = indexin(true, submissions[:, :correctSegment])[]
			timeFraction = 1.0 - submissions[firstCorrect, :submissionTime] / taskDuration
			score = round(Int, max(0.0, maxPointsAtTaskEnd + ((maxPointsPerTask - maxPointsAtTaskEnd) * timeFraction) -  ((firstCorrect - 1) * penaltyPerWrongSubmission)))
		end
		push!(dfs, DataFrame(task = submissions[1, :task], team = submissions[1, :team], score = score))
	end
end

scoreList = vcat(dfs...)

CSV.write("scoreList.csv", scoreList)

scoreSums = sort(by(scoreList, :team, :score => sum), :score_sum, rev = true)

CSV.write("scoreSums.csv", scoreSums)

######################################################

taskNames = unique(scoreList[:, :task])

teamNames = sort(unique(scoreList[:, :team]))

f = open("scoreTable.csv", "w")
write(f, "team/task,")
write(f, join(teamNames, ","))
write(f, "\n")

for t in taskNames
	write(f, t)
	write(f, ",")
	write(f, join(map(x -> "$(get(scoreList[(scoreList[:, :task] .== t) .& (scoreList[:, :team] .== x), :score], 1, 0))", teamNames), ","))
	write(f, "\n")
end

flush(f)
close(f)


######################################################


taskGroups = groupby(submissions, :task)

dfs = DataFrame[]

teamNames = sort(unique(submissions[:, :team]))

for t in taskGroups
	taskName =  t[1, :task]
	taskDuration = 60000 * (occursin("Visual", taskName) ? 5 : 8)

	for cmb in combinations(teamNames, 2)

		subs = sort(t[map(x -> x in cmb, t[:, :team]), :], :submissionTime)

		score = 0
		if (any(subs[:, :correctSegment]))
			firstCorrect = indexin(true, subs[:, :correctSegment])[]
			timeFraction = 1.0 - subs[firstCorrect, :submissionTime] / taskDuration
			score = round(Int, max(0.0, maxPointsAtTaskEnd + ((maxPointsPerTask - maxPointsAtTaskEnd) * timeFraction) -  ((firstCorrect - 1) * penaltyPerWrongSubmission)))
		end
		push!(dfs, DataFrame(task = taskName, team_a = cmb[1], team_b = cmb[2], score = score))

	end
end

scoreCombinationList = vcat(dfs...)

CSV.write("scoreCombinationList.csv", scoreCombinationList)

combinationScoreSums = sort(by(scoreCombinationList, [:team_a, :team_b], :score => sum), :score_sum, rev = true)

CSV.write("combinationScoreSums.csv", scoreCombinationList)


df = sort(combinationScoreSums, [:team_a, :team_b])

p = plot(
       layer(df, x = :team_a, y = :team_b, label = map(x -> "$x", df[:, :score_sum]), Geom.label(position=:centered)),
       layer(df, x = :team_a, y = :team_b, color = :score_sum, Geom.rectbin),
       Guide.XLabel(""), Guide.YLabel(""), Guide.ColorKey(title = "Score")
	   )

draw(PDF("combinationScore.pdf", 14cm, 12cm), p)



######################################################

taskGroups = groupby(submissions, :task)

dfs = DataFrame[]

for t in taskGroups
	teams = groupby(t, :team)
	for submissions in teams
		push!(dfs, DataFrame(task = submissions[1, :task], team = submissions[1, :team], solved = any(submissions[:, :correctSegment]) ? 1 : 0))
	end
end

solved = vcat(dfs...)

solvedCount = sort(by(solved, :team, :solved => sum), :solved_sum, rev = true)

CSV.write("tasksSolvedIndividual.csv", solvedCount)



######################################################

taskGroups = groupby(submissions, :task)

dfs = DataFrame[]

teamNames = sort(unique(submissions[:, :team]))

for t in taskGroups
	taskName =  t[1, :task]

	for cmb in combinations(teamNames, 2)

		subs = sort(t[map(x -> x in cmb, t[:, :team]), :], :submissionTime)

		push!(dfs, DataFrame(task = taskName, team_a = cmb[1], team_b = cmb[2], solved = any(subs[:, :correctSegment]) ? 1 : 0))

	end
end

CSV.write("tasksSolvedCombined.csv", solvedCount)
