import TrainingDetailDialog from './TrainingDetailDialog'

export default function CourseDetailDialog({ courseid, imageSrc, onClose }) {
  return (
    <TrainingDetailDialog
      initialKind="course"
      initialId={courseid}
      imageSrc={imageSrc}
      onClose={onClose}
    />
  )
}
