import asyncio
import uuid
from typing import Dict, Optional, Callable, Any
from pydantic import BaseModel
from datetime import datetime

class TaskStatus(BaseModel):
    task_id: str
    status: str  # "pending", "running", "completed", "failed", "cancelled"
    progress: float  # 0.0 to 1.0
    result: Optional[str] = None
    error: Optional[str] = None
    created_at: datetime
    updated_at: datetime

class Task:
    def __init__(self, task_id: str):
        self.task_id = task_id
        self.status = "pending"
        self.progress = 0.0
        self.result = None
        self.error = None
        self.created_at = datetime.now()
        self.updated_at = datetime.now()
        self.cancellation_event = asyncio.Event()

    def update_progress(self, progress: float):
        self.progress = progress
        self.updated_at = datetime.now()

    def set_status(self, status: str):
        self.status = status
        self.updated_at = datetime.now()

    def to_status_model(self) -> TaskStatus:
        return TaskStatus(
            task_id=self.task_id,
            status=self.status,
            progress=self.progress,
            result=self.result,
            error=self.error,
            created_at=self.created_at,
            updated_at=self.updated_at
        )

class TaskManager:
    def __init__(self):
        self.tasks: Dict[str, Task] = {}

    def create_task(self) -> str:
        task_id = str(uuid.uuid4())
        task = Task(task_id)
        self.tasks[task_id] = task
        return task_id

    def get_task(self, task_id: str) -> Optional[Task]:
        return self.tasks.get(task_id)

    def cancel_task(self, task_id: str) -> bool:
        task = self.get_task(task_id)
        if task and task.status in ["pending", "running"]:
            task.cancellation_event.set()
            task.set_status("cancelled")
            return True
        return False

    def remove_task(self, task_id: str):
        if task_id in self.tasks:
            del self.tasks[task_id]

task_manager = TaskManager()
