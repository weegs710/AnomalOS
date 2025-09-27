{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.claude-code-enhanced;

  # Claude Code global configuration files
  claudeConfigFiles = {
    "settings.local.json" = {
      permissions = {
        autonomous_commands = [
          "git*"
          "gh*"
          "uv*"
          "python*"
          "npm*"
          "node*"
          "yarn*"
          "pnpm*"
          "cargo*"
          "rustc*"
          "nix*"
          "direnv*"
          "cd*"
          "ls*"
          "cat*"
          "grep*"
          "find*"
          "mkdir*"
          "touch*"
          "cp*"
          "mv*"
          "chmod*"
          "chown*"
          "which*"
          "whereis*"
          "type*"
          "ps*"
          "kill*"
          "jobs*"
          "bg*"
          "fg*"
          "nohup*"
          "tmux*"
          "screen*"
          "systemctl --user*"
          "journalctl*"
          "nixos-rebuild*"
          "home-manager*"
        ];
        denied_commands = [
          "rm *"
          "dd *"
          "mkfs*"
          "fdisk*"
          "parted*"
          "systemctl start*"
          "systemctl stop*"
          "systemctl restart*"
          "systemctl enable*"
          "systemctl disable*"
          "sudo rm*"
          "sudo dd*"
          "sudo mkfs*"
          "sudo fdisk*"
          "sudo parted*"
          "chown root*"
          "chmod 777*"
        ];
      };
      mcp_servers = {
        serena = {
          enabled = true;
          command = "uvx";
          args = ["--from" "git+https://github.com/oraios/serena.git" "serena"];
        };
      };
    };
  };

  # Slash commands
  commandFiles = {
    "analyze.md" = ''
      # Analyze Component

      Deep analysis of code components, patterns, and architecture.

      ## Usage
      `/analyze [component-name]`

      ## Process
      1. **Structure Analysis**: Examine file organization and dependencies
      2. **Pattern Recognition**: Identify architectural patterns and design principles
      3. **Quality Assessment**: Evaluate code quality, testing, and documentation
      4. **Improvement Opportunities**: Suggest enhancements and optimizations
      5. **Integration Points**: Understand how component fits within larger system

      ## Analysis Focus Areas
      - Code organization and modularity
      - Dependencies and coupling
      - Performance characteristics
      - Security considerations
      - Testing coverage and strategy
      - Documentation quality
      - Maintenance complexity

      This command provides comprehensive understanding of existing code to inform development decisions.
    '';

    "primer.md" = ''
      # Context Primer

      Prime Claude with comprehensive context about existing codebase structure, patterns, and conventions.

      ## Usage
      `/primer`

      ## Process
      1. **Codebase Discovery**: Scan directory structure and identify key files
      2. **Pattern Analysis**: Understand coding patterns, conventions, and architecture
      3. **Dependency Mapping**: Identify external dependencies and integrations
      4. **Context Building**: Build comprehensive understanding of project purpose and structure
      5. **Convention Extraction**: Document implicit coding standards and practices

      ## Priming Areas
      - Project structure and organization
      - Coding conventions and style
      - Architecture patterns
      - Technology stack and dependencies
      - Build and deployment processes
      - Testing strategies
      - Documentation patterns

      This command establishes foundational context for effective code understanding and contribution.
    '';

    "generate.md" = ''
      # Generate PRP

      Generate comprehensive Product Requirements Prompt from feature specifications.

      ## Usage
      `/generate [spec-file]`

      ## Process
      1. **Specification Analysis**: Parse feature requirements and constraints
      2. **Context Integration**: Incorporate existing codebase patterns and architecture
      3. **Requirement Structuring**: Organize requirements into actionable components
      4. **Implementation Planning**: Define implementation approach and milestones
      5. **Quality Criteria**: Establish success metrics and acceptance criteria

      ## PRP Components
      - Feature overview and objectives
      - Technical requirements and constraints
      - Architecture and design considerations
      - Implementation milestones
      - Testing and validation criteria
      - Documentation requirements
      - Performance and security considerations

      This command creates structured development plans for complex features.
    '';

    "execute.md" = ''
      # Execute PRP

      Execute implementation based on Product Requirements Prompt.

      ## Usage
      `/execute [prp-file]`

      ## Process
      1. **PRP Analysis**: Parse and understand implementation requirements
      2. **Implementation Planning**: Break down into actionable development steps
      3. **Progressive Development**: Implement feature incrementally with validation
      4. **Quality Assurance**: Apply testing and validation throughout development
      5. **Documentation**: Create comprehensive documentation and examples

      ## Execution Phases
      - Requirements validation
      - Architecture implementation
      - Feature development
      - Testing and validation
      - Documentation and examples
      - Integration and deployment

      This command provides structured implementation of complex features with quality gates.
    '';
  };

  # Create the launcher script
  claudeLauncherScript = pkgs.writeShellScript "claude-launcher" ''
    #!/usr/bin/env bash

    # Enhanced Claude Code Launcher
    # Provides intelligent project navigation and global optimization features

    set -e

    # Configuration
    CLAUDE_HOME="$HOME/claude-projects"
    PROJECTS_DIR="$CLAUDE_HOME/projects"
    GLOBAL_CONFIG="$CLAUDE_HOME/.claude"

    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color

    # Emojis for visual appeal
    ROCKET="🚀"
    FOLDER="📁"
    GEAR="⚙️"
    CHECK="✅"
    CROSS="❌"
    INFO="ℹ️"

    show_banner() {
        echo -e "''${BLUE}''${ROCKET} Claude Code Project Launcher''${NC}"
        echo -e "''${CYAN}Enhanced with masterclass optimizations''${NC}"
        echo ""
    }

    show_help() {
        show_banner
        echo -e "''${YELLOW}Usage:''${NC}"
        echo "  cc                    - Show interactive project menu"
        echo "  cc [project]          - Open specific project directly"
        echo "  cc list               - List all available projects"
        echo "  cc new [name]         - Create new project"
        echo "  cc status             - Show Claude Code system status"
        echo "  cc help               - Show this help message"
        echo ""
        echo -e "''${YELLOW}Examples:''${NC}"
        echo "  cc my-app             - Open my-app project directly"
        echo "  cc new my-new-project - Create new project 'my-new-project'"
        echo ""
        echo -e "''${YELLOW}Global Features Available:''${NC}"
        echo "  • Autonomous permissions with smart hooks"
        echo "  • Specialized subagents (validation, docs, NixOS)"
        echo "  • Serena MCP for semantic understanding"
        echo "  • Parallel development workflows"
        echo "  • PRP framework for structured development"
        echo ""
    }

    list_projects() {
        echo -e "''${BLUE}''${FOLDER} Available Projects:''${NC}"
        echo ""

        if [[ ! -d "$PROJECTS_DIR" ]]; then
            echo -e "''${YELLOW}''${INFO} No projects directory found at $PROJECTS_DIR''${NC}"
            return 0
        fi

        local project_count=0
        for project_dir in "$PROJECTS_DIR"/*; do
            if [[ -d "$project_dir" ]]; then
                project_count=$((project_count + 1))
                local project_name=$(basename "$project_dir")
                local description=""

                # Try to get description from CLAUDE.md or README.md
                if [[ -f "$project_dir/CLAUDE.md" ]]; then
                    description=$(head -5 "$project_dir/CLAUDE.md" | grep -E "^#|description|Description" | head -1 | sed 's/^#*\s*//' | cut -c1-50)
                elif [[ -f "$project_dir/README.md" ]]; then
                    description=$(head -5 "$project_dir/README.md" | grep -E "^#|description|Description" | head -1 | sed 's/^#*\s*//' | cut -c1-50)
                fi

                [[ -z "$description" ]] && description="No description available"

                printf "''${GREEN}%2d.''${NC} %-20s - %s\n" "$project_count" "$project_name" "$description"
            fi
        done

        if [[ $project_count -eq 0 ]]; then
            echo -e "''${YELLOW}''${INFO} No projects found in $PROJECTS_DIR''${NC}"
            echo -e "''${CYAN}   Use 'cc new [name]' to create your first project''${NC}"
        fi
        echo ""
    }

    show_status() {
        show_banner
        echo -e "''${BLUE}''${GEAR} System Status:''${NC}"
        echo ""

        # Check global configuration
        if [[ -d "$GLOBAL_CONFIG" ]]; then
            echo -e "''${GREEN}''${CHECK}''${NC} Global configuration: Ready"

            # Count available features
            local commands_count=$(ls -1 "$GLOBAL_CONFIG/commands"/*.md 2>/dev/null | wc -l)
            local agents_count=$(ls -1 "$GLOBAL_CONFIG/agents"/*.md 2>/dev/null | wc -l)
            local hooks_count=$(ls -1 "$GLOBAL_CONFIG/hooks/scripts"/*.sh 2>/dev/null | wc -l)

            echo -e "''${CYAN}   • Slash commands: $commands_count''${NC}"
            echo -e "''${CYAN}   • Subagents: $agents_count''${NC}"
            echo -e "''${CYAN}   • Hooks: $hooks_count''${NC}"
        else
            echo -e "''${RED}''${CROSS}''${NC} Global configuration: Missing"
            echo -e "''${YELLOW}   Global configuration not found at $GLOBAL_CONFIG''${NC}"
        fi

        # Check MCP servers
        echo ""
        echo -e "''${BLUE}MCP Servers:''${NC}"
        if command -v claude >/dev/null 2>&1; then
            if claude mcp list >/dev/null 2>&1; then
                local mcp_status=$(claude mcp list 2>/dev/null || echo "Error checking MCP")
                if [[ "$mcp_status" == *"serena"* ]]; then
                    echo -e "''${GREEN}''${CHECK}''${NC} Serena: Available"
                else
                    echo -e "''${YELLOW}''${INFO}''${NC} Serena: Not configured"
                fi
            else
                echo -e "''${YELLOW}''${INFO}''${NC} MCP: Not available"
            fi
        else
            echo -e "''${RED}''${CROSS}''${NC} Claude Code: Not installed"
        fi

        # Check projects
        echo ""
        echo -e "''${BLUE}Projects:''${NC}"
        if [[ -d "$PROJECTS_DIR" ]]; then
            local project_count=$(ls -1 "$PROJECTS_DIR" 2>/dev/null | wc -l)
            echo -e "''${GREEN}''${CHECK}''${NC} Projects directory: $project_count projects"
        else
            echo -e "''${YELLOW}''${INFO}''${NC} Projects directory: Not found"
        fi

        echo ""
    }

    interactive_menu() {
        show_banner
        list_projects

        echo -e "''${YELLOW}Enter project number, name, or command:''${NC}"
        echo -e "''${CYAN}(or 'help' for more options, 'q' to quit)''${NC}"
        echo -n "► "

        read -r choice

        case "$choice" in
            q|quit|exit)
                echo -e "''${BLUE}Goodbye! ''${ROCKET}''${NC}"
                exit 0
                ;;
            help|h)
                show_help
                return
                ;;
            list|l)
                list_projects
                return
                ;;
            status|s)
                show_status
                return
                ;;
            new)
                echo -n "Enter new project name: "
                read -r project_name
                create_project "$project_name"
                return
                ;;
            "")
                echo -e "''${YELLOW}Please enter a choice''${NC}"
                return
                ;;
            *)
                # Check if it's a number
                if [[ "$choice" =~ ^[0-9]+$ ]]; then
                    local project_list=($(ls -1 "$PROJECTS_DIR" 2>/dev/null))
                    local index=$((choice - 1))
                    if [[ $index -ge 0 && $index -lt ''${#project_list[@]} ]]; then
                        open_project "''${project_list[$index]}"
                        return
                    else
                        echo -e "''${RED}Invalid project number''${NC}"
                        return
                    fi
                else
                    # Assume it's a project name
                    open_project "$choice"
                    return
                fi
                ;;
        esac
    }

    open_project() {
        local project_name="$1"
        local project_path="$PROJECTS_DIR/$project_name"

        if [[ ! -d "$project_path" ]]; then
            echo -e "''${RED}''${CROSS} Project '$project_name' not found''${NC}"
            echo ""
            echo -e "''${CYAN}Available projects:''${NC}"
            list_projects
            return 1
        fi

        echo -e "''${GREEN}''${ROCKET} Opening project: $project_name''${NC}"
        echo -e "''${CYAN}Location: $project_path''${NC}"
        echo ""

        # Change to project directory and start Claude
        cd "$project_path"

        # Show project-specific info if available
        if [[ -f "CLAUDE.md" ]]; then
            echo -e "''${BLUE}''${INFO} Project has custom Claude configuration''${NC}"
        fi

        # Start Claude Code
        exec claude
    }

    create_project() {
        local project_name="$1"

        if [[ -z "$project_name" ]]; then
            echo -e "''${RED}''${CROSS} Project name required''${NC}"
            return 1
        fi

        local project_path="$PROJECTS_DIR/$project_name"

        if [[ -d "$project_path" ]]; then
            echo -e "''${RED}''${CROSS} Project '$project_name' already exists''${NC}"
            return 1
        fi

        echo -e "''${BLUE}''${ROCKET} Creating new project: $project_name''${NC}"

        # Create project directory
        mkdir -p "$project_path"

        # Create basic project structure
        cat > "$project_path/README.md" << EOF
# $project_name

## Description
Brief description of this project.

## Setup
This project uses the enhanced Claude Code environment with:
- Global optimization features
- Specialized subagents
- Automated workflows
- Parallel development capabilities

## Usage
Run \`cc $project_name\` to open this project with Claude Code.
EOF

        # Create project-specific CLAUDE.md
        cat > "$project_path/CLAUDE.md" << EOF
# $project_name - Claude Code Configuration

## Project Context
This project inherits all global Claude Code optimizations and adds project-specific context.

## Project-Specific Guidelines
- [Add any project-specific coding standards]
- [Add domain-specific requirements]
- [Add any special considerations]

## Available Global Features
- Enhanced slash commands (/primer, /analyze, /generate, /execute)
- Specialized subagents (validation, documentation, NixOS)
- Parallel development workflows
- Automated hooks and quality gates
- Serena MCP for semantic understanding

## Getting Started
1. Use \`/primer\` to understand the project structure
2. Use \`/analyze [component]\` for deep analysis
3. Use \`/generate [spec]\` and \`/execute [prp]\` for structured development
EOF

        echo -e "''${GREEN}''${CHECK} Project created successfully''${NC}"
        echo -e "''${CYAN}Location: $project_path''${NC}"
        echo ""
        echo -e "''${YELLOW}Open with: cc $project_name''${NC}"
    }

    # Main execution
    case "''${1:-}" in
        help|--help|-h)
            show_help
            ;;
        list|--list|-l)
            list_projects
            ;;
        status|--status|-s)
            show_status
            ;;
        new|--new)
            create_project "$2"
            ;;
        "")
            # No arguments - show interactive menu
            interactive_menu
            ;;
        *)
            # Assume it's a project name
            open_project "$1"
            ;;
    esac
  '';

in
{
  options.programs.claude-code-enhanced = {
    enable = mkEnableOption "Claude Code enhanced development environment";

    projectsDirectory = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/claude-projects";
      description = "Directory where Claude Code projects are stored";
    };

    enableGlobalOptimizations = mkOption {
      type = types.bool;
      default = true;
      description = "Enable global Claude Code optimization features";
    };

    enableMcpServers = mkOption {
      type = types.bool;
      default = true;
      description = "Enable MCP server configurations";
    };

    enableParallelDevelopment = mkOption {
      type = types.bool;
      default = true;
      description = "Enable parallel development workflows";
    };
  };

  config = mkIf cfg.enable {
    # Create the claude-projects directory structure
    home.file = {
      # Global configuration
      "${cfg.projectsDirectory}/.claude/settings.local.json".text = builtins.toJSON claudeConfigFiles."settings.local.json";

      # Slash commands
      "${cfg.projectsDirectory}/.claude/commands/analyze.md".text = commandFiles."analyze.md";
      "${cfg.projectsDirectory}/.claude/commands/primer.md".text = commandFiles."primer.md";
      "${cfg.projectsDirectory}/.claude/commands/generate.md".text = commandFiles."generate.md";
      "${cfg.projectsDirectory}/.claude/commands/execute.md".text = commandFiles."execute.md";

      # Global CLAUDE.md
      "${cfg.projectsDirectory}/CLAUDE.md".text = ''
        # Claude Code Global Configuration

        This directory serves as the global foundation for all Claude Code projects, providing enhanced optimization features and masterclass patterns.

        ## Enhanced Project Structure

        ```
        ~/claude-projects/
        ├── .claude/                    # Global Claude Code configuration
        │   ├── settings.local.json     # Permission and MCP settings
        │   ├── commands/              # Reusable slash commands
        │   ├── agents/                # Specialized subagents
        │   └── hooks/                 # Development lifecycle automation
        ├── projects/                  # All your individual projects
        │   └── [project-dirs]/        # Individual project directories
        ├── templates/                 # Project templates
        ├── shared/                    # Shared resources and patterns
        └── CLAUDE.md                  # This global configuration file
        ```

        ## Core Development Principles

        **IMPORTANT**: Follow these principles proactively throughout all development:

        ### Keep It Simple and Direct
        - **KISS (Keep It Simple, Stupid)**: Choose the simplest solution that works
        - **YAGNI (You Aren't Gonna Need It)**: Don't implement features until they're actually needed
        - Focus on the immediate task without over-engineering
        - Avoid backwards compatibility unless explicitly required

        ### Effective Communication Keywords
        When thinking through complex problems, use **"ultraink"** to engage deeper reasoning.
        Mark critical requirements as **"important"** for proper attention.
        Act **"proactively"** on user needs and potential issues.

        ### Anti-Patterns to Avoid
        - Don't use terms like "production ready" that trigger over-engineering
        - Avoid implementing old code patterns for backwards compatibility
        - Don't create elaborate abstractions for simple tasks
        - Resist the urge to refactor working code unless explicitly asked

        ## Available Global Features

        ### Essential Slash Commands
        - `/primer` - Prime context for existing codebase understanding
        - `/analyze [component]` - Deep analysis of code components
        - `/generate [spec-file]` - Generate comprehensive Product Requirements Prompt
        - `/execute [prp-file]` - Execute implementation based on PRP

        ### Global Optimization Features
        This setup provides enhanced Claude Code capabilities across all projects:

        1. **Autonomous Operation**: Pre-approved safe commands for smooth workflow
        2. **MCP Integration**: Ready for Serena and other MCP servers
        3. **Context Engineering**: PRP framework for structured development
        4. **Quality Gates**: Automated validation and testing

        ## Project Workflow Integration

        ### Starting New Projects
        1. Use `cc new [project-name]` to create a new project with global optimizations
        2. Projects automatically inherit all global features
        3. Project-specific customizations go in individual CLAUDE.md files

        ### Working with Existing Projects
        1. Use `cc` to see interactive project menu
        2. Use `cc [project-name]` for direct navigation
        3. All projects inherit global optimization features
        4. Individual projects maintain their specific configurations

        ---

        *This global configuration provides masterclass optimization features to all your Claude Code projects. Use `cc` to navigate and access enhanced development capabilities!*
      '';

    };

    # Safely create project directories without clobbering existing content
    home.activation.createClaudeDirectories = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create projects directory if it doesn't exist (never clobber)
      if [[ ! -d "${cfg.projectsDirectory}/projects" ]]; then
        $DRY_RUN_CMD mkdir -p "${cfg.projectsDirectory}/projects"
        $VERBOSE_ECHO "Created projects directory"
      fi

      # Create templates directory if it doesn't exist
      if [[ ! -d "${cfg.projectsDirectory}/templates" ]]; then
        $DRY_RUN_CMD mkdir -p "${cfg.projectsDirectory}/templates"
        $VERBOSE_ECHO "Created templates directory"
      fi

      # Create shared directory if it doesn't exist
      if [[ ! -d "${cfg.projectsDirectory}/shared" ]]; then
        $DRY_RUN_CMD mkdir -p "${cfg.projectsDirectory}/shared"
        $VERBOSE_ECHO "Created shared directory"
      fi
    '';

    # Write the launcher script to a file
    home.file."bin/claude-launcher".source = claudeLauncherScript;
    home.file."bin/claude-launcher".executable = true;

    # Install dependencies (claude-code already installed globally)
    home.packages = with pkgs; [
      git
      gh
    ] ++ optionals cfg.enableMcpServers [
      # MCP server dependencies would go here
    ];
  };
}