using CSV, JSON, DaraFrames


frameRanges = CSV.read("taskFrameRanges.csv")
shotRanges = CSV.read("taskShotRanges.csv")
taskStarts = CSV.read("taskStart.csv")
padding = 10_000

tasks = taskStarts[:, :task]

#cd ...

dfs = DataFrame[]

dirs = ["Siret1-Jakub-results", "Siret2-Lada-results", "Siret3-Patrik-results", "Siret4-Franta-results", "Siret5-Premek-results", "Siret6-Vita-results", "Siret7-Tomas-results"]

for dir in dirs

    cd(dir)

    files = filter(x -> endswith(x, "json"), readdir())
    jsons = map(JSON.parsefile, files)

    team = split(dir, "-")[1]

    for i in 1:length(tasks) - 1

        task_start = taskStarts[i, :start] - padding
        task_end = taskStarts[i + 1, :start] + padding
        task_name = taskStarts[i, :task]

        relevant_jsons = filter(x -> x["timestamp"] > task_start && x["timestamp"] < task_end, jsons)

        target = frameRanges[frameRanges[:task_name] .== task_name, :]
        target_video = "$(target[1, :item_name])"
        target_start = target[1, :start_frame]
        target_end = target[1, :end_frame]

        for relevant_json in relevant_jsons

            timestamp = relevant_json["timestamp"]

            idx = findfirst(x -> x["video"] == target_video && x["frame"] >= target_start && x["frame"] <= target_end, relevant_json["results"])

            rank = idx == nothing ? -1 : relevant_json["results"][idx]["rank"]

            categories = join(relevant_json["usedCategories"], "-")
            types = join(relevant_json["usedTypes"], "-")
            sortType = join(relevant_json["sortType"], "-")

            push!(dfs, DataFrame(team = team, task = task_name, timestamp = timestamp, rank = rank, categories = categories, types = types, sortType = sortType))

        end

    end

    println(team)

    cd("..")

end



dirs = [ "vitrivr2-results", "vitrivr3-results", "vitrivr4-results", "vitrivr5-results", "vitrivr7-results", "vitrivr8-results" ]

for dir in dirs

    cd(dir)

    files = filter(x -> endswith(x, "json"), readdir())
    jsons = map(JSON.parsefile, files)

    team = split(dir, "-")[1]

    for i in 1:length(tasks) - 1

        task_start = taskStarts[i, :start] - padding
        task_end = taskStarts[i + 1, :start] + padding
        task_name = taskStarts[i, :task]

        relevant_jsons = filter(x -> x["timestamp"] > task_start && x["timestamp"] < task_end, jsons)

        target = shotRanges[frameRanges[:task_name] .== task_name, :]
        target_video = "v_" * lpad("$(target[1, :item_name])", 5, "0")
        target_start = target[1, :start_shot]
        target_end = target[1, :end_shot]

        for relevant_json in relevant_jsons

            timestamp = relevant_json["timestamp"]

            idx = findfirst(x -> x["video"] == target_video && x["shot"] >= target_start && x["shot"] <= target_end, relevant_json["results"])

            rank = idx == nothing ? -1 : relevant_json["results"][idx]["rank"]

            categories = join(relevant_json["usedCategories"], "-")
            types = join(relevant_json["usedTypes"], "-")
            sortType = join(relevant_json["sortType"], "-")

            push!(dfs, DataFrame(team = team, task = task_name, timestamp = timestamp, rank = rank, categories = categories, types = types, sortType = sortType))

        end

    end

    println(team)

    cd("..")

end

df = vcat(dfs...)

#cd ...

CSV.write("logResultRanks.csv", df)
