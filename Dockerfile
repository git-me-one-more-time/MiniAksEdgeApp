# Stage 1: Build the application
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy everything and restore dependencies
COPY *.csproj ./
RUN dotnet restore

# Copy the remaining files and build the app
COPY . ./
RUN dotnet publish -c Release -o /app/publish

# Stage 2: Run the application
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .

# Expose port and start the app
EXPOSE 8080
ENTRYPOINT ["dotnet", "edgeapp.dll"]
