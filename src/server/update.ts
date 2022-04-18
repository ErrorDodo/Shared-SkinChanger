// Check a github repository to automatically update the server code and restart the server when a new commit is pushed.
//
// Language: typescript
// Path: src\server\update.ts

import fetch from 'node-fetch';

export default async function CheckUpdates(){
    console.log("Checking for updates...");
    // Check if a new commit has been pushed to the repository.
    // Github repo is https://github.com/ErrorDodo/Shared-SkinChanger
    const request:any = await (await fetch("https://api.github.com/repos/ErrorDodo/Shared-SkinChanger/commits", {method: "GET"})).json();
    if(request.length > 0){
        const commits = request[0];
        if(commits.length > 0){
            const latestCommit = commits[0];
            const commitHash = latestCommit.sha;
            const commitMessage = latestCommit.commit.message;
            const commitDate = latestCommit.commit.author.date;
            const commitAuthor = latestCommit.commit.author.name;
    
            // Notify the user that an update is available.
            console.log(`[UPDATE] A new commit has been pushed to the repository.`);
            console.log(`[UPDATE] Commit hash: ${commitHash}`);
            console.log(`[UPDATE] Commit message: ${commitMessage}`);
            console.log(`[UPDATE] Commit date: ${commitDate}`);
            console.log(`[UPDATE] Commit author: ${commitAuthor}`);
        };
    };
};
