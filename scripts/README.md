# Debug Statement Management Scripts

This directory contains shell scripts to help manage `debugPrint` and `print` statements throughout your Flutter/Dart codebase.

## Available Scripts

### 1. `comment_debug.sh` - Comment Out Debug Statements
**Purpose**: Comments out all `debugPrint` and `print` statements in your Dart files.

**Usage**:
```bash
cd /path/to/your/project
./scripts/comment_debug.sh
```

**What it does**:
- Finds all `.dart` files in your project (excluding build directories)
- Comments out `debugPrint(...)` and `print(...)` statements by adding `//` prefix
- Shows a summary of changes made

**Example transformation**:
```dart
// Before
debugPrint('User logged in successfully');
print('Debug info: $data');

// After
// debugPrint('User logged in successfully');
// print('Debug info: $data');
```

### 2. `uncomment_debug.sh` - Uncomment Debug Statements
**Purpose**: Uncomments previously commented debug statements.

**Usage**:
```bash
cd /path/to/your/project
./scripts/uncomment_debug.sh
```

**What it does**:
- Finds all `.dart` files in your project
- Removes `//` prefix from commented `debugPrint` and `print` statements
- Shows a summary of changes made

### 3. `debug_status.sh` - Show Debug Statement Status
**Purpose**: Shows the current status of debug statements in your codebase.

**Usage**:
```bash
cd /path/to/your/project
./scripts/debug_status.sh
```

**What it does**:
- Counts active and commented debug statements
- Shows top files with most debug statements
- Provides recommendations for next actions

## Version Control Integration

These scripts are designed to work with Git version control:

- **No Backup Files**: Scripts don't create backup files since Git tracks all changes
- **Easy Restoration**: Use `git checkout -- .` to undo all changes
- **Selective Restoration**: Use `git checkout -- <file>` to restore specific files
- **Change Review**: Use `git diff` to review changes before committing

## Safety Features

- **Selective Processing**: Only processes `.dart` files, ignoring build directories
- **Safe Regex**: Uses careful pattern matching to avoid false positives
- **Git Integration**: Relies on Git for change tracking and restoration

## Usage Workflow

### For Production Builds (Comment Out Debug):
```bash
# Comment out all debug statements
./scripts/comment_debug.sh

# Review changes
git diff

# Build your app for production
flutter build apk --release
# or
flutter build ios --release

# Optionally restore debug statements for development
./scripts/uncomment_debug.sh
```

### For Development (Uncomment Debug):
```bash
# Uncomment debug statements for development
./scripts/uncomment_debug.sh

# Continue development with debug output
flutter run
```

### Restore Changes:
```bash
# If something goes wrong, restore using Git
git checkout -- .

# Or restore specific files
git checkout -- lib/apis/auth_service.dart
```

## Important Notes

1. **Run from Project Root**: Always run these scripts from your project root directory
2. **Git Required**: These scripts assume you're using Git for version control
3. **Review Changes**: Use `git diff` to review changes before committing
4. **Commit First**: Consider committing your current state before running scripts

## Excluded Directories

The scripts automatically exclude:
- `build/`
- `.dart_tool/`
- `ios/Pods/`
- `android/build/`
- `macos/build/`
- `linux/build/`
- `windows/build/`
- `web/build/`

## Git Commands for Managing Changes

```bash
# Check current status
git status

# Review all changes
git diff

# Review changes in specific file
git diff lib/apis/auth_service.dart

# Restore all files
git checkout -- .

# Restore specific file
git checkout -- lib/apis/auth_service.dart

# Commit changes
git add -A
git commit -m "Comment out debug statements for production build"
```

## Troubleshooting

### macOS/Linux
- **Permission Denied**: Make sure scripts are executable: `chmod +x scripts/*.sh`
- **No Changes**: Check if debug statements exist and aren't already commented/uncommented
- **Pattern Issues**: The scripts use conservative patterns to avoid false matches

### Windows
- **PowerShell Execution Policy**: If you get execution policy errors, run:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```
- **PowerShell Not Available**: Use the `.bat` versions instead of `.ps1`
- **Unicode Issues**: PowerShell scripts use UTF-8 encoding to preserve special characters
- **Path Issues**: Make sure to run scripts from the project root directory
- **Antivirus Blocking**: Some antivirus software may block script execution

## Script Compatibility

### macOS/Linux (Shell Scripts)
- **`comment_debug.sh`** - Comment out debug statements
- **`uncomment_debug.sh`** - Uncomment debug statements  
- **`debug_status.sh`** - Show status report

**Usage**:
```bash
# Make scripts executable (first time only)
chmod +x scripts/*.sh

# Run scripts
./scripts/comment_debug.sh
./scripts/uncomment_debug.sh
./scripts/debug_status.sh
```

### Windows (PowerShell & Batch)
- **`comment_debug.ps1/.bat`** - Comment out debug statements
- **`uncomment_debug.ps1/.bat`** - Uncomment debug statements
- **`debug_status.ps1/.bat`** - Show status report

**PowerShell Usage** (Recommended):
```powershell
# Run PowerShell scripts (may need execution policy change)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\comment_debug.ps1
.\scripts\uncomment_debug.ps1
.\scripts\debug_status.ps1
```

**Batch Usage** (Alternative):
```cmd
# Run batch scripts (no setup required)
.\scripts\comment_debug.bat
.\scripts\uncomment_debug.bat
.\scripts\debug_status.bat
```

**Windows Notes**:
- PowerShell scripts offer better output formatting and error handling
- Batch scripts work on any Windows system without setup
- If PowerShell execution is restricted, use batch scripts instead
- Both versions provide the same functionality

## Cross-Platform Usage Examples

### For Production Builds:
```bash
# macOS/Linux
./scripts/comment_debug.sh

# Windows PowerShell  
.\scripts\comment_debug.ps1

# Windows Batch
.\scripts\comment_debug.bat
```

### For Development:
```bash
# macOS/Linux
./scripts/uncomment_debug.sh

# Windows PowerShell
.\scripts\uncomment_debug.ps1

# Windows Batch
.\scripts\uncomment_debug.bat
```

### Check Status:
```bash
# macOS/Linux
./scripts/debug_status.sh

# Windows PowerShell
.\scripts\debug_status.ps1

# Windows Batch
.\scripts\debug_status.bat
```
