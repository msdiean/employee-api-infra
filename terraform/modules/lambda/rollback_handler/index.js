const { LambdaClient, ListVersionsByFunctionCommand, UpdateAliasCommand } = require("@aws-sdk/client-lambda");

exports.handler = async (event) => {
  console.log("Auto-Rollback Triggered by Alarm Event:", JSON.stringify(event));
  const lambda = new LambdaClient({});
  const functionName = process.env.TARGET_FUNCTION_NAME;
  const aliasName = process.env.TARGET_ALIAS_NAME;

  try {
    const versionsRes = await lambda.send(new ListVersionsByFunctionCommand({ FunctionName: functionName }));
    const versions = (versionsRes.Versions || [])
      .map(v => parseInt(v.Version, 10))
      .filter(v => !isNaN(v))
      .sort((a, b) => b - a);

    if (versions.length < 2) {
      console.log("No previous version available to roll back to.");
      return;
    }

    const previousVersion = String(versions[1]);
    console.log("Rolling back alias '" + aliasName + "' on function '" + functionName + "' to Version: " + previousVersion);

    await lambda.send(new UpdateAliasCommand({
      FunctionName: functionName,
      Name: aliasName,
      FunctionVersion: previousVersion
    }));

    console.log("Auto-Rollback completed successfully.");
  } catch (err) {
    console.error("Auto-Rollback failed:", err);
    throw err;
  }
};
