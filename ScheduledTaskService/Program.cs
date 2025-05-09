using System.Diagnostics;
using System.Runtime.InteropServices;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using ScheduledTaskService;

var isWindowsService = !(Debugger.IsAttached || args.Contains("--console"));

var builder = Host.CreateDefaultBuilder(args)
    .ConfigureServices((hostContext, services) =>
    {
        services.AddHostedService<Worker>();
    });

if (isWindowsService && RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
{
    builder.UseWindowsService();
}
else
{
    builder.UseConsoleLifetime();
}

builder.Build().Run();
