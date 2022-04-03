#FROM mcr.microsoft.com/dotnet/aspnet:5.0-buster-slim AS base
FROM mcr.microsoft.com/dotnet/aspnet:3.1 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443
EXPOSE 40386

#FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim AS build
FROM mcr.microsoft.com/dotnet/sdk:3.1 AS build
WORKDIR /src
COPY ["DotnetDemo/DotnetDemo.csproj", "DotnetDemo/"]

ARG SONAR=true
ARG sonarAnalysisUrl
RUN dotnet restore "DotnetDemo/DotnetDemo.csproj"
COPY  . .
WORKDIR "/src"
RUN dotnet build "DotnetDemo/DotnetDemo.csproj" -c Release -o /app

RUN if [ "$SONAR" = true ] ; then \
    apt-get update && apt-get install -y openjdk-11-jdk \
    && dotnet tool install -g dotnet-sonarscanner \
    && dotnet tool install -g dotnet-reportgenerator-globaltool \
    && export PATH="${PATH}:/root/.dotnet/tools" \
    && dotnet sonarscanner begin \
    /k:simpleapi \
    /d:sonar.host.url=http://3.109.121.132:9000/ \
    /d:sonar.coverageReportPaths="coverage/SonarQube.xml" \
    && dotnet test --collect:"XPlat Code Coverage" --results-directory ./coverage || echo "Tests Failed" \
    && reportgenerator "-reports:./coverage/*/coverage.cobertura.xml" "-targetdir:coverage" "-reporttypes:SonarQube" || echo "Reportgenerator Failed"  \
    && dotnet sonarscanner end \
    && export sonarAnalysisUrl="$(grep dashboardUrl **/report-task.txt)" \
    && echo "dashboard URL is ${sonarAnalysisUrl}"; \
    else echo "Sonarscanner Stage Skipped"; \
    fi

RUN ls -laR /src && cat /src/coverage/SonarQube.xml && cat /src/.sonarqube/out/.sonar/report-task.txt && grep dashboardUrl /src/.sonarqube/out/.sonar/report-task.txt
