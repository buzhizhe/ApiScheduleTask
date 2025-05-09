using Quartz.Impl;
using Quartz;

namespace ScheduledTaskService
{
    public class Worker : BackgroundService
    {
        private IScheduler? _scheduler;

        public override async Task StartAsync(CancellationToken cancellationToken)
        {
            var factory = new StdSchedulerFactory();
            _scheduler = await factory.GetScheduler();
            await _scheduler.Start();

            await JobScheduler.ScheduleJobs(_scheduler, "crontab.txt");
            await base.StartAsync(cancellationToken);
        }

        protected override Task ExecuteAsync(CancellationToken stoppingToken)
        {
            // Quartz 自行调度，无需处理逻辑
            return Task.CompletedTask;
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            if (_scheduler != null)
                await _scheduler.Shutdown();
            await base.StopAsync(cancellationToken);
        }
    }

}
