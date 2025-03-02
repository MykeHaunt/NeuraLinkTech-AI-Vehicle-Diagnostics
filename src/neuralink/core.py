import asyncio
from typing import Optional
from .can_bus import SecureCANBus
from .ai_models import FuelMonitoring, DTCDiagnostic
from .interfaces import HardwareManager
from ..models.vehicle_models import VehicleData

class NeuralinkCore:
    """Main control system for predictive monitoring"""
    
    def __init__(self):
        self.hw = HardwareManager()
        self.can_bus: Optional[SecureCANBus] = None
        self.fuel_ai = FuelMonitoring()
        self.dtc_analyzer = DTCDiagnostic()
        self.running = False

    async def run(self):
        """Main async monitoring loop"""
        try:
            self._initialize_hardware()
            self.running = True
            
            while self.running:
                await self._process_can_messages()
                await self._update_vehicle_state()
                await asyncio.sleep(0.05)
                
        except KeyboardInterrupt:
            self._graceful_shutdown()

    def _initialize_hardware(self):
        """Initialize platform-specific components"""
        if self.hw.is_raspberry_pi:
            self.can_bus = SecureCANBus()
            self.hw.initialize_gpio()
            
    async def _process_can_messages(self):
        """Process CAN bus data stream"""
        if self.can_bus:
            messages = await self.can_bus.read_messages()
            for msg in messages:
                self.hw.process_can_frame(msg)
                
    async def _update_vehicle_state(self):
        """Update vehicle parameters and predictions"""
        vehicle_data = self.hw.get_vehicle_state()
        self.fuel_ai.update(vehicle_data)
        self.dtc_analyzer.analyze(vehicle_data)
        
    def _graceful_shutdown(self):
        """Safe system shutdown sequence"""
        self.running = False
        if self.can_bus:
            self.can_bus.shutdown()
        self.hw.cleanup()
