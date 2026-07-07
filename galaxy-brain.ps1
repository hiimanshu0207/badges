# Galaxy Brain Badge Automation - hiimanshu0207
# Earns Galaxy Brain badge by creating Discussions, posting answers, marking accepted.
#
# Tiers: Default=1 | Bronze=8 | Silver=16 | Gold=32
#
# USAGE:
#   .\galaxy-brain.ps1                     # Gold (32 answers)
#   .\galaxy-brain.ps1 -TotalAnswers 8    # Bronze
#   .\galaxy-brain.ps1 -StartFrom 5       # Resume from #5

param(
    [int]    $TotalAnswers = 32,
    [int]    $StartFrom   = 1,
    [int]    $DelayMs     = 1500,
    [string] $RepoName    = "galaxy-brain-farm"
)

$GH_USER = "hiimanshu0207"
$GH_REPO = "$GH_USER/$RepoName"

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path","User")

function Info    { param($m) Write-Host "  $m"       -ForegroundColor Cyan   }
function Success { param($m) Write-Host "  [OK] $m"  -ForegroundColor Green  }
function Warn    { param($m) Write-Host "  [!!] $m"  -ForegroundColor Yellow }
function Err     { param($m) Write-Host "  [XX] $m"  -ForegroundColor Red    }
function Banner  { param($m) Write-Host "`n=== $m ===" -ForegroundColor Magenta }

function Show-Progress {
    param([int]$Current, [int]$Total)
    $pct    = [math]::Round(($Current / $Total) * 100)
    $filled = [math]::Round($pct / 2)
    $empty  = 50 - $filled
    $bar    = ("#" * $filled) + ("-" * $empty)
    $tier   = if ($Current -ge 32) {"GOLD"} elseif ($Current -ge 16) {"SILVER"} elseif ($Current -ge 8) {"BRONZE"} else {"..."}
    Write-Host "`r  [$bar] $pct% ($Current/$Total) [$tier]" -NoNewline -ForegroundColor Yellow
}

function Check-Badge {
    param([int]$Count)
    if ($Count -eq 1)  { Write-Host ""; Success "DEFAULT UNLOCKED! Galaxy Brain - 1 accepted answer!" }
    if ($Count -eq 8)  { Write-Host ""; Success "BRONZE UNLOCKED!  Galaxy Brain x2 - 8 accepted answers!" }
    if ($Count -eq 16) { Write-Host ""; Success "SILVER UNLOCKED!  Galaxy Brain x3 - 16 accepted answers!" }
    if ($Count -eq 32) { Write-Host ""; Success "GOLD UNLOCKED!    Galaxy Brain x4 - 32 accepted answers!" }
}

function Get-GHToken {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
    return (& gh auth token 2>&1).Trim()
}

function Invoke-GQL {
    param([string]$Query, [hashtable]$Variables = @{}, [int]$MaxRetries = 6)

    $token   = Get-GHToken
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type"  = "application/json"
    }
    $payload = @{ query = $Query }
    if ($Variables.Count -gt 0) { $payload.variables = $Variables }
    $body = $payload | ConvertTo-Json -Depth 10 -Compress

    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            $r = Invoke-RestMethod -Uri "https://api.github.com/graphql" `
                                   -Method POST `
                                   -Headers $headers `
                                   -Body $body `
                                   -ErrorAction Stop
            return $r
        } catch {
            $code = $_.Exception.Response.StatusCode.value__
            if ($code -in @(502, 503, 504)) {
                $wait = [math]::Pow(2, $attempt)
                Warn "GraphQL attempt $attempt/$MaxRetries returned $code - retrying in ${wait}s..."
                Start-Sleep -Seconds $wait
            } else {
                Warn "GraphQL error ($code): $($_.Exception.Message)"
                return $null
            }
        }
    }
    Err "GraphQL failed after $MaxRetries retries."
    return $null
}


# ── Attractive questions that pull other developers in ────────
$questions = @(
    "What is the one VS Code extension you absolutely cannot live without?",
    "Tabs vs Spaces - which do you use and why?",
    "What is the fastest way to learn Git for complete beginners?",
    "What is the best free API to practice with as a beginner developer?",
    "How do you stay motivated when a coding project gets really difficult?",
    "What programming language should a beginner learn first in 2025?",
    "What is the difference between frontend and backend development?",
    "How do you debug code when you have no idea where the bug is?",
    "What tools do you recommend for testing REST APIs?",
    "How do you manage multiple GitHub accounts on one computer?",
    "How do I run a Python script from the Windows command line?",
    "What is the easiest way to deploy a website completely for free?",
    "How do I connect a custom domain to GitHub Pages?",
    "What is the difference between HTTP and HTTPS?",
    "How do I reverse a string in Python without using a library?",
    "What is the difference between git merge and git rebase?",
    "How do I center a div both horizontally and vertically in CSS?",
    "What is the best way to learn JavaScript in 2025?",
    "How do I make my Python script run faster?",
    "What is the difference between a library and a framework?",
    "How do I handle errors in JavaScript async await functions?",
    "What is the best way to store passwords securely in a web app?",
    "How do I create a responsive navbar in pure CSS?",
    "What is the difference between SQL and NoSQL databases?",
    "How do I set up SSH keys for GitHub on Windows?",
    "What is the easiest way to build a REST API as a beginner?",
    "How do I read a JSON file in Python?",
    "What is the difference between padding and margin in CSS?",
    "How do I loop through an object in JavaScript?",
    "What is the best way to organize files in a programming project?",
    "How do I automatically format Python code on save in VS Code?",
    "What is the difference between a process and a thread in programming?"
)

$answers = @(
    "GitLens is hands-down the most powerful VS Code extension for developers. It supercharges the built-in Git features, showing inline blame, history, and comparisons. Prettier (for auto-formatting) and GitHub Copilot are close runners-up. Install GitLens from the VS Code marketplace and you will never look at a file the same way again.",
    "Both have valid use cases, but most modern style guides (PEP 8 for Python, Prettier defaults for JS) standardize on spaces - specifically 4 spaces for Python and 2 spaces for JavaScript/TypeScript. The most important rule is consistency within a project. Use .editorconfig to enforce your choice across your whole team automatically.",
    "The fastest way to learn Git is: (1) take the free official Git tutorial at git-scm.com, (2) practice with real projects on GitHub, (3) learn these 10 commands first: init, clone, add, commit, push, pull, branch, checkout, merge, status. Do not memorize everything - just learn what you need as problems arise.",
    "The best free APIs for beginners are: JSONPlaceholder (fake REST API for testing), OpenWeatherMap (weather data), PokeAPI (Pokemon data - great for practice), NASA API (astronomy images), and The Movie Database (TMDB). Start with JSONPlaceholder since it requires no API key and is perfect for learning fetch and async/await.",
    "The best strategies are: (1) break the project into tiny daily tasks so progress feels visible, (2) take breaks using the Pomodoro technique (25 min work, 5 min break), (3) join communities like GitHub Discussions, Dev.to, or Discord servers, (4) celebrate small wins, and (5) remember that every senior developer hits the same walls - it is completely normal.",
    "Start with Python in 2025. It has the simplest syntax for beginners, the largest job market outside of web development, and is used in AI/ML, automation, data science, and backend development. After Python, learn JavaScript to add web skills. Together they open almost every door in tech.",
    "Frontend is everything the user sees and interacts with in a browser - HTML, CSS, and JavaScript. Backend is the server side - databases, APIs, and business logic using languages like Python, Node.js, or Java. Full-stack developers do both. Start with frontend since you can see your results immediately in a browser.",
    "The best debugging approach: (1) read the error message carefully and Google it exactly, (2) add print statements or console.log to trace where the bug starts, (3) use a debugger (VS Code has a great built-in one), (4) rubber duck debugging - explain your code out loud to someone or something, (5) take a break and return with fresh eyes.",
    "The top tools for testing REST APIs are: Postman (most popular, GUI-based), Thunder Client (VS Code extension - no separate app needed), curl (command line, built into most systems), and Insomnia. For beginners, start with Thunder Client inside VS Code so you can test APIs without switching apps.",
    "To manage multiple GitHub accounts: (1) generate separate SSH keys for each account, (2) add each key to the respective GitHub account, (3) create a ~/.ssh/config file with Host aliases for each account, (4) set the remote URL to use the alias. This way git push uses the correct account per repo automatically.",
    "On Windows, open Command Prompt or PowerShell, navigate to your script folder with cd path/to/folder, then run python script_name.py. If python is not recognized, install Python from python.org and check 'Add Python to PATH' during installation. You can verify it works with python --version.",
    "The best free hosting options in 2025 are: GitHub Pages (static sites, completely free), Vercel (best for React/Next.js, generous free tier), Netlify (great for static and JAMstack sites), Railway (for backend/databases), and Render (for full-stack apps). For a beginner portfolio site, GitHub Pages is the simplest starting point.",
    "To connect a custom domain to GitHub Pages: (1) buy a domain from Namecheap or Google Domains, (2) go to your repo Settings > Pages, (3) enter your domain in the Custom domain field, (4) in your domain registrar DNS settings, add a CNAME record pointing to yourusername.github.io, (5) wait up to 24 hours for DNS propagation.",
    "HTTP (HyperText Transfer Protocol) sends data in plain text - anyone who intercepts it can read it. HTTPS adds TLS/SSL encryption so data is scrambled in transit. Always use HTTPS for any site handling passwords, payments, or personal data. Modern browsers now warn users when visiting HTTP sites, which hurts trust and SEO rankings.",
    "The most Pythonic way to reverse a string is using slicing: reversed_string = original[::-1]. The [::-1] slice means start from the end, go to the beginning, stepping back one character at a time. You can also use ''.join(reversed(original)) but slicing is faster and more commonly used in interviews.",
    "Git merge creates a merge commit that joins two branches, preserving the full history of both. Git rebase replays your commits on top of another branch, creating a linear history without a merge commit. Use merge for shared/public branches and rebase for cleaning up your local feature branch before a pull request.",
    "The modern way with CSS Flexbox: set the parent to display: flex, align-items: center, and justify-content: center. The parent also needs a defined height (like height: 100vh for full screen). This is the most reliable approach and works in all modern browsers without any hacks or absolute positioning tricks.",
    "The best JavaScript learning path in 2025: (1) freeCodeCamp.org (free, project-based), (2) The Odin Project (free, full curriculum), (3) javascript.info (best free reference documentation), (4) build 5 real projects as you learn. Avoid tutorial hell - start building your own projects after the basics, even if they are simple.",
    "Top ways to speed up Python: (1) use built-in functions and list comprehensions instead of loops, (2) use NumPy for numerical computations, (3) profile first with cProfile to find actual bottlenecks before optimizing, (4) use sets instead of lists for membership checks, (5) consider PyPy for CPU-intensive tasks. Always measure before and after.",
    "A library is a collection of pre-written functions you call when you choose (you are in control). A framework is a structure that calls your code - you fill in the blanks it provides (the framework is in control, following the Hollywood Principle: 'Don't call us, we'll call you'). React is a library. Django and Angular are frameworks.",
    "Wrap your async function in try/catch: async function fetchData() { try { const data = await fetch(url); } catch (error) { console.error('Error:', error); } }. You can also chain .catch() on the returned Promise. Always handle errors in async code or unhandled rejections can crash Node.js apps silently.",
    "Never store plain text passwords. Use bcrypt (in Node.js/Python) to hash passwords before storing them in your database. bcrypt adds a salt automatically to prevent rainbow table attacks. When a user logs in, use bcrypt.compare() to check their input against the stored hash. Never store, log, or transmit plain passwords.",
    "For a responsive navbar: use a flex container for the nav with space-between justification, hide the menu links on mobile using display: none with a media query below 768px, show a hamburger button on mobile using CSS, and toggle a class with JavaScript to show/hide the menu. CSS Grid or a small JavaScript toggle is all you need.",
    "SQL databases (MySQL, PostgreSQL) store data in structured tables with fixed schemas and use SQL to query. NoSQL databases (MongoDB, Redis) store data as documents, key-value pairs, or graphs with flexible schemas. Use SQL for structured relational data (users, orders, products). Use NoSQL for flexible, rapidly changing data or large-scale real-time apps.",
    "Generate an SSH key: ssh-keygen -t ed25519 -C your@email.com. Copy the public key: Get-Content ~/.ssh/id_ed25519.pub | clip. Go to GitHub Settings > SSH and GPG keys > New SSH key and paste it. Test with: ssh -T git@github.com. Then clone repos using the SSH URL (git@github.com:user/repo.git) instead of HTTPS.",
    "For beginners, the easiest path to a REST API: (1) Python + FastAPI (automatic docs, very simple syntax), (2) Node.js + Express (most tutorials available). With FastAPI: pip install fastapi uvicorn, create main.py, define routes with @app.get('/') def read_root(): return {'Hello': 'World'}, run with uvicorn main:app --reload. Done.",
    "To read a JSON file in Python: import json, then with open('data.json', 'r') as f: data = json.load(f). Now data is a Python dictionary you can work with normally. To write JSON: json.dump(data, f, indent=2). The indent=2 argument makes the output human-readable. Use json.dumps() to convert to a string instead of writing to a file.",
    "Padding is space inside the element between the content and its border. Margin is space outside the element between its border and neighboring elements. A helpful memory trick: Padding is Personal space (inside), Margin is the Moat (outside). Use padding to make an element feel roomier and margin to push elements apart from each other.",
    "Three ways to loop through a JavaScript object: (1) for...in loop: for (const key in obj) { console.log(key, obj[key]); }, (2) Object.keys(obj).forEach(key => ...), (3) Object.entries(obj).forEach(([key, value]) => ...). Use Object.entries() when you need both the key and value - it is the most modern and readable approach.",
    "A clean project structure: keep a src or app folder for all source code, separate folders for components, utils, tests, and assets, a config folder for environment configs, and docs for documentation. Use meaningful names, keep files small and focused on one thing, and add a README.md at the root. Consistency matters more than any specific structure.",
    "In VS Code: install the Prettier extension, then go to Settings (Ctrl+,), search for 'Format On Save' and check the box, then search for 'Default Formatter' and select Prettier. For Python specifically, also install the Black formatter extension and set it as the Python default formatter. Now every Ctrl+S auto-formats your file.",
    "A process is an independent program running in its own memory space - if it crashes, it does not affect other processes. A thread is a unit of execution within a process that shares the same memory. Multiple threads in one process can run concurrently but must be careful about shared data (race conditions). Python threads are limited by the GIL for CPU tasks - use multiprocessing instead."
)

# ════════════════════════════════════════════════════════════
Banner "Galaxy Brain Badge Automation - $GH_REPO"
# ════════════════════════════════════════════════════════════

Banner "Step 1: Checking gh CLI..."
try { $v = & gh --version 2>&1 | Select-Object -First 1; Success "gh found: $v" }
catch { Err "gh CLI not found!"; exit 1 }
$authStatus = & gh auth status 2>&1
if ($LASTEXITCODE -ne 0) { Err "Not logged in. Run: gh auth login"; exit 1 }
Success "Authenticated as $GH_USER"

Banner "Step 2: Setting up repo..."
$repoCheck = & gh repo view $GH_REPO 2>&1
if ($LASTEXITCODE -ne 0) {
    Info "Creating repo: $GH_REPO ..."
    & gh repo create $RepoName --public --description "Galaxy Brain badge farm - Dev Q and A" --add-readme 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Err "Failed to create repo"; exit 1 }
    Success "Repo created: https://github.com/$GH_REPO"
    Start-Sleep -Milliseconds 3000
} else {
    Success "Repo exists: https://github.com/$GH_REPO"
}

Banner "Step 3: Fetching repo info..."
$repoRest = & gh api repos/$GH_REPO 2>&1 | ConvertFrom-Json
if (-not $repoRest -or -not $repoRest.node_id) { Err "Could not fetch repo info"; exit 1 }
$repoId = $repoRest.node_id
Success "Repo node_id: $repoId"
if (-not $repoRest.has_discussions) {
    & gh api --method PATCH repos/$GH_REPO -f has_discussions=true | Out-Null
    Success "Discussions enabled!"
} else {
    Success "Discussions already enabled"
}

Banner "Step 4: Finding Q and A category..."
$catQuery = @"
query {
  repository(owner: "$GH_USER", name: "$RepoName") {
    discussionCategories(first: 20) {
      nodes { id name isAnswerable }
    }
  }
}
"@
$catData    = Invoke-GQL -Query $catQuery
$qaCategory = $catData.data.repository.discussionCategories.nodes | Where-Object { $_.isAnswerable -eq $true } | Select-Object -First 1

if (-not $qaCategory) {
    Err "No Q and A category found!"
    Info "Please create one at: https://github.com/$GH_REPO/discussions/categories/new"
    Info "Choose format: Question and Answer"
    Read-Host "Press Enter once created..."
    $catData    = Invoke-GQL -Query $catQuery
    $qaCategory = $catData.data.repository.discussionCategories.nodes | Where-Object { $_.isAnswerable -eq $true } | Select-Object -First 1
    if (-not $qaCategory) { Err "Still no Q and A category. Exiting."; exit 1 }
}
Success "Category: '$($qaCategory.name)' (ID: $($qaCategory.id))"

Banner "Step 5: Creating $TotalAnswers accepted answers (from #$StartFrom)..."
Info "Discussions live at: https://github.com/$GH_REPO/discussions"
Info "Press Ctrl+C to pause. Resume with: .\galaxy-brain.ps1 -StartFrom <N>"
Write-Host ""

$acceptedCount = $StartFrom - 1

for ($i = $StartFrom; $i -le $TotalAnswers; $i++) {

    $idx    = ($i - 1) % $questions.Count
    $ts     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $qTitle = $questions[$idx]
    $qBody  = "$($questions[$idx])`n`nLooking for practical advice and real-world experience. Any help appreciated!`n`n*Posted: $ts*"
    $aBody  = "$($answers[$idx])`n`n---`n*Accepted answer. Feel free to add more tips in the comments!*"

    # Create Discussion
    $createQuery = @"
mutation {
  createDiscussion(input: {
    repositoryId: "$repoId"
    categoryId: "$($qaCategory.id)"
    title: $(($qTitle | ConvertTo-Json))
    body: $(($qBody | ConvertTo-Json))
  }) {
    discussion { id number url }
  }
}
"@
    $createResult = Invoke-GQL -Query $createQuery
    if (-not $createResult -or -not $createResult.data -or -not $createResult.data.createDiscussion) {
        Warn "Discussion #$i create failed - skipping"
        continue
    }
    $discussionId  = $createResult.data.createDiscussion.discussion.id
    $discussionNum = $createResult.data.createDiscussion.discussion.number
    Start-Sleep -Milliseconds $DelayMs

    # Post Answer
    $commentQuery = @"
mutation {
  addDiscussionComment(input: {
    discussionId: "$discussionId"
    body: $(($aBody | ConvertTo-Json))
  }) {
    comment { id }
  }
}
"@
    $commentResult = Invoke-GQL -Query $commentQuery
    if (-not $commentResult -or -not $commentResult.data -or -not $commentResult.data.addDiscussionComment) {
        Warn "Comment on discussion #$discussionNum failed - skipping"
        continue
    }
    $commentId = $commentResult.data.addDiscussionComment.comment.id
    Start-Sleep -Milliseconds $DelayMs

    # Mark as Accepted Answer
    $markQuery = @"
mutation {
  markDiscussionCommentAsAnswer(input: {
    id: "$commentId"
  }) {
    discussion { id }
  }
}
"@
    $markResult = Invoke-GQL -Query $markQuery
    if (-not $markResult -or -not $markResult.data -or -not $markResult.data.markDiscussionCommentAsAnswer) {
        Warn "Mark as answer failed for discussion #$discussionNum - skipping"
        continue
    }

    $acceptedCount++
    Show-Progress -Current $acceptedCount -Total $TotalAnswers
    Check-Badge -Count $acceptedCount
    Start-Sleep -Milliseconds $DelayMs
}

Write-Host ""
Banner "Done! $acceptedCount accepted answers in $GH_REPO"
Write-Host ""
Write-Host "  View your profile:    https://github.com/$GH_USER"  -ForegroundColor Cyan
Write-Host "  View discussions:     https://github.com/$GH_REPO/discussions" -ForegroundColor Cyan
Write-Host ""
if ($acceptedCount -ge 1)  { Write-Host "  [DEFAULT] Galaxy Brain     - UNLOCKED" -ForegroundColor DarkCyan   }
if ($acceptedCount -ge 8)  { Write-Host "  [BRONZE]  Galaxy Brain x2  - UNLOCKED" -ForegroundColor DarkYellow }
if ($acceptedCount -ge 16) { Write-Host "  [SILVER]  Galaxy Brain x3  - UNLOCKED" -ForegroundColor Gray       }
if ($acceptedCount -ge 32) { Write-Host "  [GOLD]    Galaxy Brain x4  - UNLOCKED" -ForegroundColor Yellow     }
Write-Host ""
Write-Host "  Badges may take a few minutes to appear on your profile." -ForegroundColor DarkGray
