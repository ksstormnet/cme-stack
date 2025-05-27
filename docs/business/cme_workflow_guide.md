# CME Workflow & Process Guide

## Communication Approach

### **Start Strategic, Then Drill Down**
- Begin every significant topic with business context and architectural implications
- Discuss the "why" before diving into the "how" 
- Move from high-level decisions to specific implementation details
- Ask clarifying questions about scope and priorities when unclear

### **Output Format Expectations**
- **Always generate artifacts** for:
  - Docker Compose configurations
  - Configuration files (YAML, JSON, etc.)
  - Scripts and automation code
  - Documentation updates
  - Database schemas and migrations
- **Ask for preferred format** when output type isn't specified
- **Provide options** when multiple valid approaches exist

## Task Breakdown Philosophy

### **Direct Implementation**
When creating implementation deliverables:
- **Complete Configurations**: Provide full file contents ready for copy/paste
- **Comprehensive Comments**: Include detailed explanations within configurations
- **Testing Validation**: Include commands and steps to verify functionality
- **Error Handling**: Anticipate common issues and provide troubleshooting guidance
- **Documentation Updates**: Maintain README and changelog consistency

### **Task-Based Sessions**
- **One conversation per branch/task** with complete implementation cycle
- **Test and debug** within the same conversation
- **End with commit pattern**: "let's commit this work" triggers documentation updates
- **Self-contained deliverables** ready for immediate implementation

## Project-Specific Guidelines

### **Infrastructure Focus**
Current priority is **Phase 1: Core Infrastructure**:
- Docker Compose service configurations
- Network topology and service communication
- Secrets management integration (1Password Connect)
- Database schema design and connections
- Basic monitoring and logging setup

### **Quality Standards**
- All configurations must include proper error handling
- Services must be containerized with appropriate resource limits
- Network segmentation must follow security principles
- Secrets must never be hardcoded in configurations
- All changes must be compatible with dev/staging/prod environments

### **Decision Points**
When encountering technical choices:
- **Present options** with pros/cons for architectural decisions
- **Recommend approach** based on project context and constraints
- **Explain tradeoffs** in terms of complexity, performance, and maintainability
- **Consider future phases** when making current decisions

## Conversation Flow Patterns

### **Planning Sessions**
1. **Scope Definition**: What are we building in this session?
2. **Approach Discussion**: How should we tackle this technically?
3. **Dependencies Review**: What needs to be in place first?
4. **Deliverables Agreement**: What specific outputs will we create?
5. **Success Criteria**: How will we know it's working?

### **Implementation Sessions**
1. **Task Definition**: Confirm specific implementation scope
2. **Technical Approach**: Generate complete configurations as artifacts
3. **Integration Validation**: Test service connectivity and functionality
4. **Documentation Updates**: README and changelog maintenance
5. **Commit Preparation**: Summary and next steps

### **Problem-Solving Sessions**
1. **Issue Analysis**: Understand the specific problem
2. **Root Cause Investigation**: Identify underlying causes
3. **Solution Options**: Present multiple approaches
4. **Implementation Plan**: Step-by-step resolution
5. **Prevention Strategy**: Avoid similar issues

## Code Generation Standards

### **Docker Compose Files**
- Use proper YAML formatting with consistent indentation
- Include comprehensive environment variable definitions
- Define explicit network assignments
- Specify resource limits and health checks
- Include detailed comments for complex configurations

### **Configuration Files**
- Follow service-specific best practices
- Include security-focused defaults
- Use environment variable substitution where appropriate
- Document non-obvious configuration choices
- Provide examples for customization

### **Scripts and Automation**
- Include proper error handling and logging
- Use environment variable validation
- Provide usage examples and help text
- Follow shell scripting best practices
- Include prerequisite checks

## Validation Approach

### **Before Implementation**
- Confirm technical approach aligns with business objectives
- Verify dependencies and prerequisites are met
- Review security and compliance implications
- Check resource requirements and constraints

### **During Implementation**
- Provide testing commands for each component
- Include integration validation steps
- Verify network connectivity and service communication
- Test secrets injection and configuration loading

### **After Implementation**
- Document what was built and how it works
- Update architecture documentation
- Identify next logical implementation steps
- Note any technical debt or optimization opportunities

## Error Handling Philosophy

### **Anticipate Common Issues**
- Service startup order dependencies
- Network connectivity problems
- Secrets loading failures
- Resource constraint violations
- Configuration syntax errors

### **Provide Debugging Guidance**
- Include diagnostic commands for troubleshooting
- Explain log file locations and key error patterns
- Suggest systematic debugging approaches
- Provide rollback procedures when things go wrong

## Success Criteria

### **Each Conversation Should Result In**
- Clear understanding of what was accomplished
- Working code/configurations that can be immediately implemented
- Specific next steps for continued progress
- Updated documentation reflecting current state
- Validation approach for testing the implementation

### **Phase Completion Indicators**
- All services start successfully
- Network communication works as designed
- Secrets are properly injected and secured
- Monitoring provides visibility into system health
- Documentation accurately reflects implementation

---

*This guide defines our collaborative development process, ensuring we maintain strategic focus while delivering practical, implementable solutions.*