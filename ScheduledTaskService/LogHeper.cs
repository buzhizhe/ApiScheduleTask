using System;
using System.Collections.Concurrent;
using System.IO;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

public static class LogHelper
{
    // 日志队列和后台处理任务
    private static readonly BlockingCollection<(string message, string prefix)> _logQueue = new BlockingCollection<(string, string)>();
    private static readonly SemaphoreSlim _writerSemaphore = new SemaphoreSlim(1, 1);
    private static StreamWriter _writer;
    private static string _currentLogFilePath;
    private static int _bufferedLogCount;

    // 清理配置
    private static readonly Timer _cleanupTimer;
    private const int LogRetentionDays = 7;
    private const int FlushInterval = 10;  // 每10条刷新一次缓冲区

    static LogHelper()
    {
        // 注册进程退出事件
        AppDomain.CurrentDomain.ProcessExit += (sender, args) => Shutdown();
        // 启动后台日志处理线程
        Task.Factory.StartNew(ProcessLogQueue, TaskCreationOptions.LongRunning);

        // 每小时清理一次旧日志
        _cleanupTimer = new Timer(_ =>
            _ = CleanOldLogsAsync(),
            null,
            TimeSpan.Zero,
            TimeSpan.FromHours(12));
    }
    public static void log(string message, string prefix, bool do_flush)
    {
        if (do_flush)
        {
            WriteLogInternalSync(message, prefix);
        }
        else
        {
            log(message, prefix); // 调用原有队列处理
        }
    }

    private static void WriteLogInternalSync(string message, string prefix)
    {
        try
        {
            var logDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "log");
            Directory.CreateDirectory(logDir);

            var fileName = $"{prefix}{DateTime.Now:yyyyMMdd}.log";
            var filePath = Path.Combine(logDir, fileName);

            _writerSemaphore.Wait(); // 同步等待锁
            try
            {
                // 切换文件时需要关闭旧文件
                if (_writer == null || _currentLogFilePath != filePath)
                {
                    _writer?.Dispose();
                    _currentLogFilePath = filePath;
                    _writer = new StreamWriter(filePath, true, Encoding.UTF8)
                    {
                        AutoFlush = false
                    };
                }

                _writer.WriteLine($"{DateTime.Now:yyyy-MM-dd HH:mm:ss} {message}");
                _writer.Flush(); // 强制立即写入磁盘
            }
            finally
            {
                _writerSemaphore.Release();
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"紧急日志写入失败: {ex.Message}");
        }
    }
    public static void log(string message, string prefix = "info_") =>
        _logQueue.Add((message, prefix));

    public static Task LogAsync(string message, string prefix = "info_")
    {
        //什么也不做，直接返回
       // return Task.CompletedTask;
       return Task.Run(() => _logQueue.Add((message, prefix)));
    }


    private static async Task ProcessLogQueue()
    {
        foreach (var item in _logQueue.GetConsumingEnumerable())
        {
            await WriteLogInternal(item.message, item.prefix);
        }
    }

    private static async Task WriteLogInternal(string message, string prefix)
    {
        try
        {
            var logDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "log");
            Directory.CreateDirectory(logDir);

            var fileName = $"{prefix}{DateTime.Now:yyyyMMdd}.log";
            var filePath = Path.Combine(logDir, fileName);

            await _writerSemaphore.WaitAsync();
            try
            {
                // 切换文件时需要关闭旧文件
                if (_writer == null || _currentLogFilePath != filePath)
                {
                    _writer?.Dispose();
                    _currentLogFilePath = filePath;
                    _writer = new StreamWriter(filePath, true, Encoding.UTF8)
                    {
                        AutoFlush = false  // 禁用自动刷新
                    };
                }

                await _writer.WriteLineAsync($"{DateTime.Now:yyyy-MM-dd HH:mm:ss} {message}");

                // 缓冲控制
                if (++_bufferedLogCount >= FlushInterval)
                {
                    await _writer.FlushAsync();
                    _bufferedLogCount = 0;
                }
            }
            finally
            {
                _writerSemaphore.Release();
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"日志写入失败: {ex.Message}");
        }
    }

    private static async Task CleanOldLogsAsync()
    {
        try
        {
            var logDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "log");
            if (!Directory.Exists(logDir)) return;

            var cutoffDate = DateTime.Now.AddDays(-LogRetentionDays);

            foreach (var filePath in Directory.GetFiles(logDir, "*.log"))
            {
                try
                {
                    var fileInfo = new FileInfo(filePath);
                    if (fileInfo.CreationTime < cutoffDate)
                    {
                        await Task.Run(() => fileInfo.Delete());  // 异步删除
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"删除旧日志失败: {filePath} - {ex.Message}");
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"清理日志错误: {ex.Message}");
        }
    }

    public static void Shutdown()
    {
        // 停止接收新日志
        _logQueue.CompleteAdding();

        // 确保队列剩余日志写入
        while (_logQueue.Count > 0)
        {
            Thread.Sleep(100);
        }

        // 释放资源
        _writerSemaphore.Wait();
        try
        {
            _writer?.Flush();
            _writer?.Dispose();
            _cleanupTimer?.Dispose();
        }
        finally
        {
            _writerSemaphore.Release();
        }
    }
}