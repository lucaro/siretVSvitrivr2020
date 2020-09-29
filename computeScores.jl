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

CSV.write("combinationScoreSums.csv", combinationScoreSums)


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


######################################################

combinationScoreSums = CSV.read("combinationScoreSums.csv")
scoreSums = CSV.read("scoreSums.csv")

df = sort(vcat(combinationScoreSums,
       DataFrame(team_a = scoreSums[:, :team], team_b = scoreSums[:, :team], score_sum = scoreSums[:, :score_sum])),
       [:team_a, :team_b])

p = plot(
       layer(df, x = :team_a, y = :team_b, label = map(x -> "$x", df[:, :score_sum]), Geom.label(position=:centered)),
       layer(df, x = :team_a, y = :team_b, color = :score_sum, Geom.rectbin),
       Guide.XLabel(""), Guide.YLabel(""), Guide.ColorKey(title = "Score"), Scale.color_continuous(minvalue=1000, maxvalue=3000)
	   )

draw(PDF("combinationScoreWithIndividual.pdf", 14cm, 12cm), p)



######################################################


df = DataFrame(task = map(x -> reduce(replace, ["KIS Visual" => "V", "KIS Textual" => "T"], init=x), submissions[:, :task]), team = map(x -> split(x, " ")[1], submissions[:, :team]), submissionTime = submissions[:, :submissionTime], correct = submissions[:, :correctSegment])

df = df[df[:, :correct], :]

p = plot(df, y = :submissionTime, x = :task, color = :team, Geom.boxplot, Guide.XLabel(""), Guide.YLabel(""), Guide.ColorKey(title=""), Scale.y_continuous(labels = x -> "$(round(Int, x / 60000)) min"), Guide.YTicks(ticks = collect(0:60000:(8*60000))), Theme(key_position=:bottom))
draw(PDF("submissionTimes.pdf", 20cm, 6cm), p)


######################################################


df = DataFrame(team = map(x -> split(x, " ")[1], submissions[:, :team]), submissionTime = submissions[:, :submissionTime], correct = submissions[:, :correctSegment], type = map(x -> split(x, " ")[2], submissions[:, :task]))

df = df[df[:, :correct], :]
df[:, :group] =  df[:, :type] .* " - " .* df[:, :team]
df = sort(df, :group)

color_scale = Scale.color_discrete_manual(colorant"#F04941", colorant"#2992F0", colorant"#A3221C", colorant"#3670A3")

p = plot(df, x = :submissionTime, color = :group, Geom.density(bandwidth=10_000), Coord.cartesian(xmin = 0, xmax = 9*60000), Scale.x_continuous(labels = x -> "$(round(Int, x / 60000)) min"),
 Guide.XTicks(ticks = collect(0:60000:(9*60000))), Guide.XLabel("Time until correct submission"), Guide.ColorKey(title="Team, Type (Number of correct Submissions)", labels = ["siret, Textual (94) ", "vitrivr, Textual (86) ", "siret, Visual (102) ", "vitrivr, Visual (87) "]), color_scale, Theme(key_position=:bottom))
draw(PDF("submissionTimeDistribution.pdf", 14cm, 12cm), p)

######################################################

teamNames = sort(unique(submissions[:, :team]))
tasks = sort(unique(submissions[:, :task]))


df = by(vcat(submissions, DataFrame(team = repeat(teamNames, inner = length(tasks)), task = repeat(tasks, outer = length(teamNames)), submissionTime = 0, correctItem = false, correctSegment = false)), [:task, :team], :correctItem => any)

CSV.write("tasksSolvedList.csv", sort(df, [:team, :task]))


######################################################

tasks = JSON.parsefile("siret_vs_vitrivr_competition.json")["tasks"]

dfs = DataFrame[]

for task in tasks

	fps = task["item"]["fps"]

	push!(dfs, DataFrame(
		task_name = task["name"],
		item_name = task["item"]["name"],
		start_frame = round(Int, floor(fps * (task["temporalRange"]["start"]["value"] - 1))),
		end_frame = round(Int, ceil(fps * (task["temporalRange"]["end"]["value"] + 1)))
		)
	)
end

df = vcat(dfs...)

CSV.write("taskFrameRanges.csv", df)

######################################################

ranks = CSV.read("logResultRanks.csv")

df = ranks[ranks[:rank] .> 0, :]
df = by(df, [:team, :task], :rank => minimum)
df[:, :task] = map(x -> split(x, " ")[2], df[:, :task])
df[:, :team] = map(x -> x[1:end-1], df[:, :team])
df[:, :group] =  df[:, :task] .* " - " .* df[:, :team]
df = sort(df, :group)

color_scale = Scale.color_discrete_manual(colorant"#F04941", colorant"#2992F0", colorant"#A3221C", colorant"#3670A3")

p = plot(df, x = :rank_minimum, color = :group, Geom.density(bandwidth = 0.1), Scale.x_log10, Coord.cartesian(xmin = 0, xmax = 5), Guide.XLabel("Best Rank"), Guide.ColorKey(title="Team, Type (Number of Task Instances)", labels = ["siret, Textual (123) ", "vitrivr, Textual (92) ", "siret, Visual (129) ", "vitrivr, Visual (88) "]), color_scale, Theme(key_position=:bottom))
draw(PDF("bestRankDistribution.pdf", 14cm, 12cm), p)