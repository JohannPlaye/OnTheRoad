import SwiftUI

struct TripRowView: View {
    let trip: Trip

    var body: some View {
        HStack(spacing: 14) {
            // Time column
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.formattedStartTime)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(trip.formattedEndTime)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.45))
            }
            .frame(width: 54, alignment: .leading)

            Rectangle()
                .fill(Color.appPink)
                .frame(width: 2)
                .cornerRadius(1)

            // Main info
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 12) {
                    label(icon: "road.lanes", text: trip.formattedDistance)
                    label(icon: "timer",      text: trip.formattedDuration)
                }
                if let motif = trip.motif, !motif.isEmpty {
                    Text(motif)
                        .font(.caption)
                        .foregroundColor(.appPink)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func label(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.appCyan)
            Text(text)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
    }
}
