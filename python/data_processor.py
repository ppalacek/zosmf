#!/usr/bin/env python3
"""
data_processor.py - Main data processing script for zOS workflow

This script demonstrates Python integration with zOS workflows including:
- Dataset processing and analysis
- USS file operations
- Environment-specific logic
- Error handling and logging
- Integration with zOS system calls

Usage:
    python3 data_processor.py --work-dir /u/user/workflow --environment TEST

Arguments:
    --work-dir: Base working directory
    --environment: Target environment (DEV/TEST/PROD)
    --log-dir: Directory for log files
    --output-dir: Directory for output files
"""

import sys
import os
import argparse
import logging
import json
import subprocess
import datetime
from pathlib import Path
import re

class WorkflowDataProcessor:
    """Main class for workflow data processing"""
    
    def __init__(self, work_dir, environment, log_dir=None, output_dir=None):
        self.work_dir = Path(work_dir)
        self.environment = environment
        self.log_dir = Path(log_dir) if log_dir else self.work_dir / "logs"
        self.output_dir = Path(output_dir) if output_dir else self.work_dir / "output"
        
        # Create directories if they don't exist
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Setup logging
        self.setup_logging()
        
        # Configuration
        self.config = self.load_configuration()
        
        self.logger.info(f"Initialized WorkflowDataProcessor")
        self.logger.info(f"Work Directory: {self.work_dir}")
        self.logger.info(f"Environment: {self.environment}")
        self.logger.info(f"Log Directory: {self.log_dir}")
        self.logger.info(f"Output Directory: {self.output_dir}")
    
    def setup_logging(self):
        """Setup logging configuration"""
        log_file = self.log_dir / f"python_processor_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        
        # Create logger
        self.logger = logging.getLogger('WorkflowDataProcessor')
        self.logger.setLevel(logging.INFO)
        
        # Create formatters
        file_formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        console_formatter = logging.Formatter(
            '%(levelname)s - %(message)s'
        )
        
        # File handler
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.INFO)
        file_handler.setFormatter(file_formatter)
        
        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)
        console_handler.setFormatter(console_formatter)
        
        # Add handlers to logger
        self.logger.addHandler(file_handler)
        self.logger.addHandler(console_handler)
        
        self.logger.info(f"Logging initialized - log file: {log_file}")
    
    def load_configuration(self):
        """Load configuration from files"""
        config = {
            'environment': self.environment,
            'processing_date': datetime.datetime.now().isoformat(),
            'version': '1.0.0'
        }
        
        # Load environment configuration if available
        env_config_file = self.work_dir / "config" / "environment.conf"
        if env_config_file.exists():
            self.logger.info(f"Loading configuration from: {env_config_file}")
            try:
                with open(env_config_file, 'r') as f:
                    for line in f:
                        if '=' in line and not line.strip().startswith('#'):
                            key, value = line.strip().split('=', 1)
                            config[key] = value
                self.logger.info("Configuration loaded successfully")
            except Exception as e:
                self.logger.warning(f"Error loading configuration: {e}")
        
        return config
    
    def execute_tso_command(self, command):
        """Execute TSO command and return output"""
        self.logger.info(f"Executing TSO command: {command}")
        try:
            # Use subprocess to execute TSO command
            # Note: This is a simplified example - adjust for your system
            result = subprocess.run(
                ['tso', command],
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode == 0:
                self.logger.info("TSO command executed successfully")
                return result.stdout
            else:
                self.logger.error(f"TSO command failed with return code: {result.returncode}")
                self.logger.error(f"Error output: {result.stderr}")
                return None
                
        except subprocess.TimeoutExpired:
            self.logger.error("TSO command timed out")
            return None
        except Exception as e:
            self.logger.error(f"Error executing TSO command: {e}")
            return None
    
    def list_datasets(self, hlq):
        """List datasets with given HLQ"""
        self.logger.info(f"Listing datasets with HLQ: {hlq}")
        
        # Execute LISTCAT command
        command = f"LISTCAT LEVEL('{hlq}') ALL"
        output = self.execute_tso_command(command)
        
        datasets = []
        if output:
            # Parse dataset names from output
            lines = output.split('\n')
            for line in lines:
                # Look for dataset names (simplified parsing)
                if hlq in line and 'NONVSAM' in line:
                    dataset_match = re.search(r'([A-Z0-9.]+)', line)
                    if dataset_match:
                        datasets.append(dataset_match.group(1))
        
        self.logger.info(f"Found {len(datasets)} datasets")
        return datasets
    
    def analyze_dataset_content(self, dataset_name):
        """Analyze content of a dataset"""
        self.logger.info(f"Analyzing dataset: {dataset_name}")
        
        analysis = {
            'dataset_name': dataset_name,
            'analysis_time': datetime.datetime.now().isoformat(),
            'record_count': 0,
            'total_bytes': 0,
            'sample_records': [],
            'statistics': {}
        }
        
        try:
            # Read dataset content (simplified example)
            # In a real implementation, you would use appropriate z/OS dataset access methods
            
            # For demonstration, we'll simulate dataset analysis
            analysis['record_count'] = 100  # Simulated
            analysis['total_bytes'] = 8000   # Simulated
            analysis['sample_records'] = [
                'RECORD001 TEST DATA FOR ENVIRONMENT',
                'RECORD002 PROCESSING DATE: 2024-01-01',
                'RECORD003 PROCESSING TIME: 12:00:00'
            ]
            
            analysis['statistics'] = {
                'min_record_length': 80,
                'max_record_length': 80,
                'avg_record_length': 80,
                'empty_records': 0,
                'comment_records': 0
            }
            
            self.logger.info(f"Dataset analysis completed: {analysis['record_count']} records")
            
        except Exception as e:
            self.logger.error(f"Error analyzing dataset {dataset_name}: {e}")
            analysis['error'] = str(e)
        
        return analysis
    
    def process_environment_data(self):
        """Process data based on environment"""
        self.logger.info(f"Processing data for environment: {self.environment}")
        
        processing_result = {
            'environment': self.environment,
            'processing_time': datetime.datetime.now().isoformat(),
            'steps_completed': [],
            'results': {}
        }
        
        try:
            if self.environment == 'DEV':
                # Development-specific processing
                self.logger.info("Executing development processing logic")
                processing_result['steps_completed'].append('dev_validation')
                processing_result['steps_completed'].append('dev_debug_output')
                processing_result['results']['dev_mode'] = True
                processing_result['results']['debug_level'] = 'high'
                
            elif self.environment == 'TEST':
                # Test-specific processing
                self.logger.info("Executing test processing logic")
                processing_result['steps_completed'].append('test_validation')
                processing_result['steps_completed'].append('test_performance_check')
                processing_result['results']['test_mode'] = True
                processing_result['results']['performance_baseline'] = '100ms'
                
            elif self.environment == 'PROD':
                # Production-specific processing
                self.logger.info("Executing production processing logic")
                processing_result['steps_completed'].append('prod_validation')
                processing_result['steps_completed'].append('prod_audit_log')
                processing_result['steps_completed'].append('prod_backup')
                processing_result['results']['prod_mode'] = True
                processing_result['results']['audit_enabled'] = True
                processing_result['results']['backup_created'] = True
            
            # Common processing for all environments
            processing_result['steps_completed'].append('common_processing')
            processing_result['results']['workflow_version'] = self.config.get('version', '1.0.0')
            processing_result['results']['success'] = True
            
            self.logger.info("Environment-specific processing completed successfully")
            
        except Exception as e:
            self.logger.error(f"Error in environment processing: {e}")
            processing_result['results']['success'] = False
            processing_result['results']['error'] = str(e)
        
        return processing_result
    
    def generate_reports(self, datasets_analysis, processing_result):
        """Generate reports from processing results"""
        self.logger.info("Generating processing reports")
        
        timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # Generate JSON report
        json_report_file = self.output_dir / f"processing_report_{timestamp}.json"
        json_report = {
            'workflow_info': {
                'version': self.config.get('version', '1.0.0'),
                'environment': self.environment,
                'processing_date': datetime.datetime.now().isoformat(),
                'work_directory': str(self.work_dir)
            },
            'datasets_analysis': datasets_analysis,
            'processing_result': processing_result,
            'summary': {
                'total_datasets': len(datasets_analysis),
                'processing_success': processing_result.get('results', {}).get('success', False),
                'steps_completed': len(processing_result.get('steps_completed', [])),
                'environment': self.environment
            }
        }
        
        try:
            with open(json_report_file, 'w') as f:
                json.dump(json_report, f, indent=2)
            self.logger.info(f"JSON report created: {json_report_file}")
        except Exception as e:
            self.logger.error(f"Error creating JSON report: {e}")
        
        # Generate text report
        text_report_file = self.output_dir / f"processing_summary_{timestamp}.txt"
        try:
            with open(text_report_file, 'w') as f:
                f.write("=" * 60 + "\n")
                f.write("          WORKFLOW PROCESSING REPORT\n")
                f.write("=" * 60 + "\n")
                f.write(f"Date: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"Environment: {self.environment}\n")
                f.write(f"Work Directory: {self.work_dir}\n")
                f.write(f"Workflow Version: {self.config.get('version', '1.0.0')}\n")
                f.write("\n")
                
                f.write("DATASET ANALYSIS SUMMARY:\n")
                f.write("-" * 30 + "\n")
                f.write(f"Total Datasets Analyzed: {len(datasets_analysis)}\n")
                for analysis in datasets_analysis:
                    f.write(f"  {analysis['dataset_name']}: {analysis['record_count']} records\n")
                f.write("\n")
                
                f.write("PROCESSING RESULTS:\n")
                f.write("-" * 20 + "\n")
                f.write(f"Environment: {processing_result['environment']}\n")
                f.write(f"Success: {processing_result.get('results', {}).get('success', False)}\n")
                f.write(f"Steps Completed: {len(processing_result.get('steps_completed', []))}\n")
                f.write("Steps:\n")
                for step in processing_result.get('steps_completed', []):
                    f.write(f"  - {step}\n")
                f.write("\n")
                
                f.write("CONFIGURATION:\n")
                f.write("-" * 15 + "\n")
                for key, value in self.config.items():
                    f.write(f"  {key}: {value}\n")
                f.write("\n")
                
                f.write("=" * 60 + "\n")
                f.write("              END OF REPORT\n")
                f.write("=" * 60 + "\n")
            
            self.logger.info(f"Text report created: {text_report_file}")
        except Exception as e:
            self.logger.error(f"Error creating text report: {e}")
    
    def run_processing(self):
        """Main processing method"""
        self.logger.info("=" * 50)
        self.logger.info("Starting workflow data processing")
        self.logger.info("=" * 50)
        
        try:
            # Get HLQ from configuration
            hlq = self.config.get('HLQ', 'USER')
            self.logger.info(f"Using HLQ: {hlq}")
            
            # Step 1: List and analyze datasets
            self.logger.info("Step 1: Analyzing datasets")
            datasets = self.list_datasets(hlq)
            datasets_analysis = []
            
            for dataset in datasets:
                analysis = self.analyze_dataset_content(dataset)
                datasets_analysis.append(analysis)
            
            # Step 2: Environment-specific processing
            self.logger.info("Step 2: Environment-specific processing")
            processing_result = self.process_environment_data()
            
            # Step 3: Generate reports
            self.logger.info("Step 3: Generating reports")
            self.generate_reports(datasets_analysis, processing_result)
            
            # Step 4: Summary
            self.logger.info("Step 4: Processing summary")
            success = processing_result.get('results', {}).get('success', False)
            
            if success:
                self.logger.info("Workflow data processing completed successfully")
                print("SUCCESS: Workflow data processing completed")
                return 0
            else:
                self.logger.error("Workflow data processing failed")
                print("FAILED: Workflow data processing failed")
                return 1
                
        except Exception as e:
            self.logger.error(f"Unexpected error in processing: {e}")
            print(f"ERROR: {e}")
            return 1

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='zOS Workflow Data Processor')
    parser.add_argument('--work-dir', required=True, help='Base working directory')
    parser.add_argument('--environment', required=True, choices=['DEV', 'TEST', 'PROD'], 
                       help='Target environment')
    parser.add_argument('--log-dir', help='Directory for log files')
    parser.add_argument('--output-dir', help='Directory for output files')
    
    args = parser.parse_args()
    
    # Create processor instance
    processor = WorkflowDataProcessor(
        work_dir=args.work_dir,
        environment=args.environment,
        log_dir=args.log_dir,
        output_dir=args.output_dir
    )
    
    # Run processing
    exit_code = processor.run_processing()
    
    sys.exit(exit_code)

if __name__ == '__main__':
    main()