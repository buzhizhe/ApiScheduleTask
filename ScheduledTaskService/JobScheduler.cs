using Quartz;

public static class JobScheduler
{

    public static async Task ScheduleJobs(IScheduler scheduler, string filePath)
    {
        if (!File.Exists(filePath))
        {
            await LogHelper.LogAsync("crontab.txt not found", "init");
            throw new FileNotFoundException("crontab.txt not found.");
        }

        var lines = await File.ReadAllLinesAsync(filePath);
        int index = 0;

        foreach (var line in lines)
        {
            var trimmed = line.Trim();
            if (string.IsNullOrWhiteSpace(trimmed) || trimmed.StartsWith("#")) continue;

            // 去除注释（# 后面的内容）
            var noComment = trimmed.Split('#')[0].Trim();

            var parts = noComment.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length < 7)
            {
                await LogHelper.LogAsync($"Invalid config (not 6 cron + URL): {line}", "init");
                throw new FormatException($"Invalid cron format in line: {line}");
            }

            var cron = string.Join(' ', parts.Take(6));
            var url = string.Join(' ', parts.Skip(6));

            try
            {
                var job = JobBuilder.Create<HttpJob>()
                    .WithIdentity($"job_{index++}_")
                    .UsingJobData("url", url)
                    .Build();

                var trigger = TriggerBuilder.Create()
                    .WithCronSchedule(cron)
                    .Build();

                await scheduler.ScheduleJob(job, trigger);
                await LogHelper.LogAsync($"Scheduled {url} with cron: {cron}", "init");
            }
            catch (Exception ex)
            {
                await LogHelper.LogAsync($"Failed to schedule: {line} => {ex.Message}", "init");
                throw; // 中止程序
            }
        }
    }


}
