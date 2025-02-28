================================
# NeuraLinkTech AI Vehicle Diagnostics - Setup Utility
# Version 4.0.2 Initializer
# ====================================================================================================

import os
import sys
import platform
import subprocess
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('install.log'),
        logging.StreamHandler()
    ]
)

class SystemInitializer:
    """Universal system preparation and configuration"""
    
    def __init__(self):
        self.system_info = {
            'os': platform.system(),
            'arch': platform.machine(),
            'python_version': sys.version_info,
            'env_path': Path.cwd()
        }
        self.requirements = {
            'core': [
                'numpy>=1.21.0',
                'pandas>=1.3.0',
                'psutil>=5.8.0',
                'python-dateutil>=2.8.2'
            ],
            'ai': [
                'torch>=1.12.0' if self.system_info['arch'] != 'armv7l' 
                else 'torch==1.11.0',
                'tensorflow>=2.9.0'
            ],
            'platform_specific': {
                'Linux': ['pycoral>=2.0.0'],
                'Darwin': [],
                'Windows': []
            }
        }
        
    def _run_command(self, command: list):
        try:
            result = subprocess.run(
                command,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            logging.info(f"Command succeeded: {' '.join(command)}")
            return True
        except subprocess.CalledProcessError as e:
            logging.error(f"Command failed: {' '.join(command)}\nError: {e.stderr}")
            return False

    def create_directory_structure(self):
        """Create necessary system directories"""
        dirs = [
            'config',
            'models/embedded',
            'models/desktop',
            'logs',
            'data/vehicle_records',
            'utils'
        ]
        
        for directory in dirs:
            path = self.system_info['env_path'] / directory
            try:
                path.mkdir(parents=True, exist_ok=True)
                logging.info(f"Created directory: {path}")
            except OSError as e:
                logging.error(f"Directory creation failed: {str(e)}")

    def install_dependencies(self):
        """Install required packages with platform-specific handling"""
        # Install core requirements
        self._run_command([sys.executable, '-m', 'pip', 'install'] + 
                         self.requirements['core'])
        
        # Install AI components
        self._run_command([sys.executable, '-m', 'pip', 'install'] +
                         self.requirements['ai'])
        
        # Platform-specific packages
        platform_pkgs = self.requirements['platform_specific'].get(
            self.system_info['os'], []
        )
        if platform_pkgs:
            self._run_command([sys.executable, '-m', 'pip', 'install'] + platform_pkgs)

    def configure_environment(self):
        """Set up platform-specific configurations"""
        if self.system_info['os'] == 'Linux':
            self._configure_linux()
        elif self.system_info['os'] == 'Windows':
            self._configure_windows()
        elif self.system_info['os'] == 'Darwin':
            self._configure_macos()

    def _configure_linux(self):
        """Linux/Raspberry Pi specific configurations"""
        # Enable hardware interfaces
        if 'raspberry' in platform.platform().lower():
            logging.info("Configuring Raspberry Pi hardware...")
            self._run_command(['sudo', 'raspi-config', 'nonint', 'do_camera', '0'])
            self._run_command(['sudo', 'raspi-config', 'nonint', 'do_i2c', '0'])
            self._run_command(['sudo', 'usermod', '-a', '-G', 'gpio', os.getlogin()])
            
        # Set up udev rules for hardware access
        udev_rules = [
            'SUBSYSTEM=="i2c-dev", GROUP="i2c", MODE="0660"',
            'SUBSYSTEM=="gpio*", PROGRAM="/bin/sh -c \'chown -R root:gpio /sys/class/gpio && chmod -R 770 /sys/class/gpio; chown -R root:gpio /sys/devices/platform/soc/*.gpio/gpio && chmod -R 770 /sys/devices/platform/soc/*.gpio/gpio\''
        ]
        
        try:
            with open('/etc/udev/rules.d/99-neuralink.rules', 'w') as f:
                f.write('\n'.join(udev_rules))
            self._run_command(['sudo', 'udevadm', 'control', '--reload'])
            self._run_command(['sudo', 'udevadm', 'trigger'])
        except PermissionError:
            logging.error("Permission denied for udev configuration")

    def generate_config(self):
        """Create default configuration file"""
        config_template = f"""
        [System]
        platform = auto
        log_level = INFO
        
        [AI]
        default_model = {'embedded' if 'arm' in self.system_info['arch'] else 'desktop'}
        inference_threads = {'2' if 'arm' in self.system_info['arch'] else '8'}
        
        [Hardware]
        camera_enabled = {'true' if self.system_info['os'] == 'Linux' else 'false'}
        sensor_polling = 1000
        """
        
        config_path = self.system_info['env_path'] / 'config/system.cfg'
        try:
            with open(config_path, 'w') as f:
                f.write(config_template)
            logging.info(f"Generated default config at {config_path}")
        except IOError as e:
            logging.error(f"Config creation failed: {str(e)}")

    def verify_installation(self):
        """Check critical system components"""
        checks = {
            'Model directories': Path('models').exists(),
            'Configuration file': Path('config/system.cfg').exists(),
            'Python version': self.system_info['python_version'] >= (3, 8),
            'Torch installation': self._check_module('torch'),
            'TensorFlow installation': self._check_module('tensorflow')
        }
        
        if all(checks.values()):
            logging.info("System verification passed")
            return True
            
        logging.error("Installation verification failed. Issues detected:")
        for check, status in checks.items():
            if not status:
                logging.error(f"- {check}")
        return False

    def _check_module(self, module: str) -> bool:
        try:
            __import__(module)
            return True
        except ImportError:
            return False

def main():
    initializer = SystemInitializer()
    
    print("""
    ================================
    NeuraLinkTech AI Setup Utility
    ================================
    1. Full Installation
    2. Verify Existing Installation
    3. Generate Configuration Only
    4. Exit
    """)
    
    choice = input("Select operation [1-4]: ").strip()
    
    if choice == '1':
        initializer.create_directory_structure()
        initializer.install_dependencies()
        initializer.configure_environment()
        initializer.generate_config()
        if initializer.verify_installation():
            print("\nInstallation successful!\nRun: python NeuraLinkTech_v4.0.2.py")
        else:
            print("\nInstallation completed with warnings. Check install.log")
    
    elif choice == '2':
        if initializer.verify_installation():
            print("System verification passed")
        else:
            print("System verification failed - check install.log")
    
    elif choice == '3':
        initializer.generate_config()
        print("Configuration file generated")
    
    elif choice == '4':
        print("Exiting setup")
    
    else:
        print("Invalid selection")

if __name__ == "__main__":
    main()