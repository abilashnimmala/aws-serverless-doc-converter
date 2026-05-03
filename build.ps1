# build.ps1
param (
    [string]$srcDir = "src",
    [string]$buildDir = "build"
)

# Create build directory if it doesn't exist
if (Test-Path $buildDir) {
    Remove-Item -Recurse -Force $buildDir
}
New-Item -ItemType Directory -Path $buildDir

# Copy source files
Copy-Item "$srcDir\*.py" $buildDir

# Install dependencies for Linux (Lambda)
pip install `
    --platform manylinux2014_x86_64 `
    --target $buildDir `
    --implementation cp `
    --python-version 3.9 `
    --only-binary=:all: `
    -r "$srcDir\requirements.txt"

# Add S3 CORS configuration
# We need to allow the S3 website origin to upload to the input bucket
Write-Host "Please ensure your INPUT S3 bucket has CORS enabled to allow PUT requests from the website origin."
