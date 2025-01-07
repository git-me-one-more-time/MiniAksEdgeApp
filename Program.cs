var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

var region = Environment.GetEnvironmentVariable("REGION") ?? "[ENV_VAR REGION was not set!!]";

app.MapGet("/", () => $"This response is handled by the {region} edge.");

app.Run();

