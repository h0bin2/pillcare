from ultralytics import YOLO

class YOLOModel:
    def __init__(self, model_path: str):
        self.model = YOLO(model_path)

    def predict(self, image_path: str):
        return self.model.predict(image_path)

model = YOLOModel("/Users/hyeongbinham/StudioProjects/flutter-back/cv/yolo11n_best.pt")