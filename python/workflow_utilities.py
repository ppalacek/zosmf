#!/usr/bin/env python3
"""
workflow_utilities.py - Utility functions for zOS workflow operations

This module provides utility functions for common workflow operations including:
- Dataset operations
- USS file manipulation
- Configuration management
- Logging utilities
- System integration
"""

import os
import sys
import json
import subprocess
import datetime
import logging
from pathlib import Path
import re
from typing import Dict, List, Optional, Union

class DatasetUtilities:
    """Utilities for dataset operations"""
    
    @staticmethod
    def execute_mvs_command(command: str, timeout: int = 60) -> Optional[str]:
        """Execute MVS command and return output"""
        try:
            result = subprocess.run(
                ['tso', command],
                capture_output=True,
                text=True,
                timeout=timeout
            )
            
            if result.returncode == 0:
                return result.stdout
            else:
                logging.error(f"MVS command failed: {command}")
                logging.error(f"Error: {result.stderr}")
                return None
                
        except subprocess.TimeoutExpired:
            logging.error(f"MVS command timed out: {command}")
            return None
        except Exception as e:
            logging.error(f"Error executing MVS command: {e}")
            return None
    
    @staticmethod
    def check_dataset_exists(dataset_name: str) -> bool:
        """Check if dataset exists"""
        command = f"LISTCAT ENT('{dataset_name}')"
        output = DatasetUtilities.execute_mvs_command(command)
        return output is not None and dataset_name in output
    
    @staticmethod
    def get_dataset_info(dataset_name: str) -> Dict:
        """Get detailed dataset information"""
        info = {
            'name': dataset_name,
            'exists': False,
            'type': None,
            'organization': None,
            'record_format': None,
            'record_length': None,
            'block_size': None,
            'space_allocated': None,
            'space_used': None
        }
        
        if DatasetUtilities.check_dataset_exists(dataset_name):
            info['exists'] = True
            
            # Get detailed info using LISTCAT
            command = f"LISTCAT ENT('{dataset_name}') ALL"
            output = DatasetUtilities.execute_mvs_command(command)
            
            if output:
                # Parse output for dataset attributes
                # This is a simplified parser - extend as needed
                lines = output.split('\n')
                for line in lines:
                    if 'NONVSAM' in line:
                        info['type'] = 'NONVSAM'
                    elif 'VSAM' in line:
                        info['type'] = 'VSAM'
                    elif 'RECFM' in line:
                        match = re.search(r'RECFM-([A-Z]+)', line)
                        if match:
                            info['record_format'] = match.group(1)
                    elif 'LRECL' in line:
                        match = re.search(r'LRECL-(\d+)', line)
                        if match:
                            info['record_length'] = int(match.group(1))
        
        return info
    
    @staticmethod
    def list_datasets_by_pattern(pattern: str) -> List[str]:
        """List datasets matching pattern"""
        command = f"LISTCAT LEVEL('{pattern}') ALL"
        output = DatasetUtilities.execute_mvs_command(command)
        
        datasets = []
        if output:
            lines = output.split('\n')
            for line in lines:
                # Extract dataset names from LISTCAT output
                match = re.search(r'([A-Z0-9.]+)', line)
                if match and '.' in match.group(1):
                    dataset = match.group(1)
                    if dataset not in datasets:
                        datasets.append(dataset)
        
        return sorted(datasets)

class USSUtilities:
    """Utilities for USS operations"""
    
    @staticmethod
    def ensure_directory(path: Union[str, Path]) -> bool:
        """Ensure directory exists, create if necessary"""
        try:
            Path(path).mkdir(parents=True, exist_ok=True)
            return True
        except Exception as e:
            logging.error(f"Error creating directory {path}: {e}")
            return False
    
    @staticmethod
    def read_file_safely(file_path: Union[str, Path], encoding: str = 'utf-8') -> Optional[str]:
        """Safely read file content"""
        try:
            with open(file_path, 'r', encoding=encoding) as f:
                return f.read()
        except Exception as e:
            logging.error(f"Error reading file {file_path}: {e}")
            return None
    
    @staticmethod
    def write_file_safely(file_path: Union[str, Path], content: str, encoding: str = 'utf-8') -> bool:
        """Safely write file content"""
        try:
            with open(file_path, 'w', encoding=encoding) as f:
                f.write(content)
            return True
        except Exception as e:
            logging.error(f"Error writing file {file_path}: {e}")
            return False
    
    @staticmethod
    def get_file_info(file_path: Union[str, Path]) -> Dict:
        """Get file information"""
        path = Path(file_path)
        info = {
            'path': str(path),
            'exists': path.exists(),
            'is_file': False,
            'is_directory': False,
            'size': 0,
            'modified_time': None,
            'permissions': None
        }
        
        if path.exists():
            stat = path.stat()
            info['is_file'] = path.is_file()
            info['is_directory'] = path.is_dir()
            info['size'] = stat.st_size
            info['modified_time'] = datetime.datetime.fromtimestamp(stat.st_mtime).isoformat()
            info['permissions'] = oct(stat.st_mode)[-3:]
        
        return info
    
    @staticmethod
    def execute_shell_command(command: str, cwd: Optional[str] = None, timeout: int = 60) -> Dict:
        """Execute shell command and return result"""
        result = {
            'command': command,
            'returncode': None,
            'stdout': '',
            'stderr': '',
            'success': False
        }
        
        try:
            proc_result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                cwd=cwd,
                timeout=timeout
            )
            
            result['returncode'] = proc_result.returncode
            result['stdout'] = proc_result.stdout
            result['stderr'] = proc_result.stderr
            result['success'] = proc_result.returncode == 0
            
        except subprocess.TimeoutExpired:
            result['stderr'] = 'Command timed out'
        except Exception as e:
            result['stderr'] = str(e)
        
        return result

class ConfigurationManager:
    """Configuration management utilities"""
    
    def __init__(self, config_dir: Union[str, Path]):
        self.config_dir = Path(config_dir)
        self.config_dir.mkdir(parents=True, exist_ok=True)
        self.config = {}
    
    def load_config_file(self, filename: str) -> Dict:
        """Load configuration from file"""
        config_file = self.config_dir / filename
        config = {}
        
        if config_file.exists():
            try:
                if filename.endswith('.json'):
                    with open(config_file, 'r') as f:
                        config = json.load(f)
                else:
                    # Handle .conf format (key=value)
                    with open(config_file, 'r') as f:
                        for line in f:
                            line = line.strip()
                            if line and not line.startswith('#') and '=' in line:
                                key, value = line.split('=', 1)
                                config[key.strip()] = value.strip()
                
                logging.info(f"Loaded configuration from {config_file}")
            except Exception as e:
                logging.error(f"Error loading configuration from {config_file}: {e}")
        
        return config
    
    def save_config_file(self, filename: str, config: Dict) -> bool:
        """Save configuration to file"""
        config_file = self.config_dir / filename
        
        try:
            if filename.endswith('.json'):
                with open(config_file, 'w') as f:
                    json.dump(config, f, indent=2)
            else:
                # Handle .conf format (key=value)
                with open(config_file, 'w') as f:
                    f.write(f"# Configuration file generated on {datetime.datetime.now()}\n")
                    for key, value in config.items():
                        f.write(f"{key}={value}\n")
            
            logging.info(f"Saved configuration to {config_file}")
            return True
        except Exception as e:
            logging.error(f"Error saving configuration to {config_file}: {e}")
            return False
    
    def get_workflow_config(self) -> Dict:
        """Get complete workflow configuration"""
        config = {}
        
        # Load different configuration files
        env_config = self.load_config_file('environment.conf')
        status_config = self.load_config_file('workflow_status.conf')
        
        config.update(env_config)
        config.update(status_config)
        
        return config
    
    def update_workflow_status(self, status_updates: Dict) -> bool:
        """Update workflow status"""
        status_file = 'workflow_status.conf'
        current_status = self.load_config_file(status_file)
        
        # Add timestamp
        status_updates['LAST_UPDATE'] = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        # Merge updates
        current_status.update(status_updates)
        
        return self.save_config_file(status_file, current_status)

class WorkflowLogger:
    """Enhanced logging utilities for workflows"""
    
    def __init__(self, log_dir: Union[str, Path], name: str = 'workflow'):
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self.name = name
        self.logger = None
        self.setup_logger()
    
    def setup_logger(self):
        """Setup logger with file and console handlers"""
        self.logger = logging.getLogger(self.name)
        self.logger.setLevel(logging.INFO)
        
        # Clear existing handlers
        self.logger.handlers.clear()
        
        # File handler with rotation
        timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
        log_file = self.log_dir / f"{self.name}_{timestamp}.log"
        
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.INFO)
        
        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)
        
        # Formatter
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        file_handler.setFormatter(formatter)
        console_handler.setFormatter(formatter)
        
        # Add handlers
        self.logger.addHandler(file_handler)
        self.logger.addHandler(console_handler)
    
    def info(self, message: str):
        """Log info message"""
        if self.logger:
            self.logger.info(message)
    
    def warning(self, message: str):
        """Log warning message"""
        if self.logger:
            self.logger.warning(message)
    
    def error(self, message: str):
        """Log error message"""
        if self.logger:
            self.logger.error(message)
    
    def debug(self, message: str):
        """Log debug message"""
        if self.logger:
            self.logger.debug(message)

class SystemUtilities:
    """System-level utilities"""
    
    @staticmethod
    def get_system_info() -> Dict:
        """Get system information"""
        info = {
            'timestamp': datetime.datetime.now().isoformat(),
            'user': os.getenv('USER', 'unknown'),
            'home': os.getenv('HOME', '/'),
            'path': os.getenv('PATH', ''),
            'python_version': sys.version,
            'platform': sys.platform
        }
        
        # Get additional system info
        try:
            import platform
            info['system'] = platform.system()
            info['node'] = platform.node()
            info['processor'] = platform.processor()
        except ImportError:
            pass
        
        return info
    
    @staticmethod
    def check_prerequisites() -> Dict:
        """Check system prerequisites"""
        checks = {
            'python_available': True,
            'tso_available': False,
            'directories_writable': True,
            'system_commands': {}
        }
        
        # Check if TSO is available
        try:
            result = subprocess.run(['which', 'tso'], capture_output=True, text=True)
            checks['tso_available'] = result.returncode == 0
        except:
            pass
        
        # Check common system commands
        commands = ['ls', 'cp', 'mv', 'mkdir', 'chmod']
        for cmd in commands:
            try:
                result = subprocess.run(['which', cmd], capture_output=True, text=True)
                checks['system_commands'][cmd] = result.returncode == 0
            except:
                checks['system_commands'][cmd] = False
        
        return checks

# Example usage and testing functions
def test_utilities():
    """Test utility functions"""
    print("Testing zOS Workflow Utilities")
    print("=" * 40)
    
    # Test system info
    print("System Information:")
    system_info = SystemUtilities.get_system_info()
    for key, value in system_info.items():
        print(f"  {key}: {value}")
    
    print("\nPrerequisite Check:")
    prereqs = SystemUtilities.check_prerequisites()
    for key, value in prereqs.items():
        print(f"  {key}: {value}")
    
    # Test USS utilities
    print("\nUSS Utilities Test:")
    test_dir = Path("/tmp/workflow_test")
    USSUtilities.ensure_directory(test_dir)
    
    test_file = test_dir / "test.txt"
    USSUtilities.write_file_safely(test_file, "Test content")
    
    file_info = USSUtilities.get_file_info(test_file)
    print(f"  Test file info: {file_info}")
    
    # Cleanup
    import shutil
    shutil.rmtree(test_dir, ignore_errors=True)

if __name__ == '__main__':
    test_utilities()