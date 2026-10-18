let courses = [
  { courseid: 1, 
    coursename: "初階重訓", 
    coursetype: "重量訓練", 
    description: "適合初學者的重量訓練課程，每堂 60 分鐘。", 
    durationmin: 60, price: 800, status: "上架" },
  { courseid: 2, 
    coursename: "中階重訓", 
    coursetype: "重量訓練", 
    description: "適合已有基礎、想進一步提升肌力的學員。", 
    durationmin: 60, price: 1000, status: "上架" },
  { courseid: 3, 
    coursename: "高階重訓", 
    coursetype: "重量訓練", 
    description: "適合有訓練經驗、想挑戰較高強度的學員。", 
    durationmin: 60, price: 1200, status: "上架" },
  { courseid: 4, 
    coursename: "筋膜放鬆", 
    coursetype: "伸展放鬆", 
    description: "透過筋膜放鬆練習，舒緩運動後的緊繃感。", 
    durationmin: 60, price: 700, status: "上架" },
  { courseid: 5, 
    coursename: "TRX", 
    coursetype: "懸吊訓練", 
    description: "利用懸吊器材進行全身肌力與核心訓練。", 
    durationmin: 60, price: 900, status: "上架" }
];

let coaches = [];

let coachCourses = [
  { coachid: 1, courseid: 1 },
  { coachid: 1, courseid: 2 },
  { coachid: 1, courseid: 5 },
  { coachid: 2, courseid: 4 },
  { coachid: 3, courseid: 2 },
  { coachid: 3, courseid: 3 },
  { coachid: 4, courseid: 1 },
  { coachid: 4, courseid: 4 },
  { coachid: 5, courseid: 3 },
  { coachid: 5, courseid: 5 }
];