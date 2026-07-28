const { LambdaClient, GetAliasCommand, ListVersionsByFunctionCommand, UpdateAliasCommand } = require("@aws-sdk/client-lambda");

exports.handler = async (event) => {
  console.log("Auto-Rollback Triggered by Alarm Event:", JSON.stringify(event));
  const lambda = new LambdaClient({});
  const functionName = process.env.TARGET_FUNCTION_NAME;
  const aliasName = process.env.TARGET_ALIAS_NAME;

  try {
    const aliasRes = await lambda.send(new GetAliasCommand({ FunctionName: functionName, Name: aliasName }));
    const currentVersion = aliasRes.FunctionVersion;
    console.log("Current alias '" + aliasName + "' version: " + currentVersion);

    const versionsRes = await lambda.send(new ListVersionsByFunctionCommand({ FunctionName: functionName }));
    const versions = (versionsRes.Versions || [])
      .map(v => parseInt(v.Version, 10))
      .filter(v => !isNaN(v))
      .sort((a, b) => b - a);

    if (versions.length < 2) {
      console.log("No alternative version available to roll back to.");
      return;
    }

    const latestVersion = String(versions[0]);
    const previousVersion = String(versions[1]);

    // Smart Switch: If currently pointing to previous version, switch to latest version; otherwise switch to previous version.
    let targetVersion = previousVersion;
    if (currentVersion === previousVersion) {
      targetVersion = latestVersion;
    }

    console.log("Switching alias '" + aliasName + "' on function '" + functionName + "' from Version " + currentVersion + " to Target Version: " + targetVersion);

    await lambda.send(new UpdateAliasCommand({
      FunctionName: functionName,
      Name: aliasName,
      FunctionVersion: targetVersion
    }));

    console.log("Auto-Rollback completed successfully. Alias '" + aliasName + "' now points to Version " + targetVersion);
  } catch (err) {
    console.error("Auto-Rollback failed:", err);
    throw err;
  }
};
