using Quartz;

public class HttpJob : IJob
{
    public async Task Execute(IJobExecutionContext context)
    {
        var url = context.JobDetail.JobDataMap.GetString("url");
        var jobKey = context.JobDetail.Key; // 包含 Name 和 Group
        var identity = jobKey.Name;

        try
        {
            using var client = new HttpClient();
            var response = await client.GetAsync(url);
            var content = await response.Content.ReadAsStringAsync();
            await LogHelper.LogAsync($"[OK] {url} => {response.StatusCode},cont={content}", identity);
        }
        catch (Exception ex)
        {
            await LogHelper.LogAsync($"[ERR] {url} => {ex.Message}", identity);
        }
    }
}
