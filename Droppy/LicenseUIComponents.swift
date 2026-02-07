import SwiftUI

// MARK: - Live Preview Card (Activation Window — pre-activation)

struct LicenseLivePreviewCard: View {
    let email: String
    let keyDisplay: String
    let isActivated: Bool
    var accentColor: Color = .blue
    var enableInteractiveEffects: Bool = true

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top: brand + status
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: "d.square.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("DROPPY")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.8)
                        .foregroundStyle(.white.opacity(0.92))
                }

                Spacer()

                Text(isActivated ? "ACTIVE" : "PENDING")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(isActivated ? .white : .white.opacity(0.6))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.white.opacity(isActivated ? 0.2 : 0.1))
                    )
            }

            Spacer()
                .frame(height: 2)

            // License key — large, monospaced
            Text(keyDisplay)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .tracking(1.2)
                .lineLimit(1)
                .truncationMode(.middle)

            // Email
            Text(nonEmpty(email) ?? "you@yourmail.com")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.11))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .scaleEffect(enableInteractiveEffects && isHovering ? 1.01 : 1.0)
        .onHover { hovering in
            guard enableInteractiveEffects else { return }
            withAnimation(DroppyAnimation.hover) {
                isHovering = hovering
            }
        }
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Identity Card (Activated state — settings & activation window)

struct LicenseIdentityCard: View {
    let title: String
    let subtitle: String
    let email: String
    let keyHint: String?
    let verifiedAt: Date?
    var accentColor: Color = .blue
    let footer: AnyView?
    var enableInteractiveEffects: Bool

    @State private var isHovering = false

    init(
        title: String,
        subtitle: String,
        email: String,
        keyHint: String?,
        verifiedAt: Date?,
        accentColor: Color = .blue,
        footer: AnyView? = nil,
        enableInteractiveEffects: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.email = email
        self.keyHint = keyHint
        self.verifiedAt = verifiedAt
        self.accentColor = accentColor
        self.footer = footer
        self.enableInteractiveEffects = enableInteractiveEffects
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("PRO")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.12))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            // Meta rows
            VStack(alignment: .leading, spacing: 0) {
                metaRow(
                    label: "Email",
                    value: nonEmpty(email) ?? "Not provided"
                )

                if let keyHint = nonEmpty(keyHint) {
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 1)
                    metaRow(
                        label: "License",
                        value: keyHint
                    )
                }

                if let verifiedAt {
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 1)
                    HStack {
                        metaRow(
                            label: "Verified",
                            value: verifiedAt.formatted(date: .abbreviated, time: .shortened)
                        )
                        if let footer {
                            footer
                                .padding(.trailing, 16)
                        }
                    }
                } else if let footer {
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 1)
                    HStack {
                        Spacer(minLength: 0)
                        footer
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(Color(white: 0.11))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .scaleEffect(enableInteractiveEffects && isHovering ? 1.01 : 1.0)
        .onHover { hovering in
            guard enableInteractiveEffects else { return }
            withAnimation(DroppyAnimation.hover) {
                isHovering = hovering
            }
        }
    }

    private func metaRow(label: String, value: String) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary.opacity(0.88))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
