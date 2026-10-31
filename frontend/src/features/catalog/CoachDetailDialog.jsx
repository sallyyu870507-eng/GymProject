import TrainingDetailDialog from './TrainingDetailDialog'

export default function CoachDetailDialog({ coachid, imageSrc, onClose }) {
  return (
    <TrainingDetailDialog
      initialKind="coach"
      initialId={coachid}
      imageSrc={imageSrc}
      onClose={onClose}
    />
  )
}
