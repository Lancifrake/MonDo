# Missing Screens & Features - TIER 3 & TIER 4

## Overview
This document catalogs **21 missing screens and features** for MonDo mobile app, organized by priority tier and feature area. These will be implemented in future phases after MVP completion.

---

## TIER 3 - Core Features (Priority High)

### 1. Account Recovery Flow (3 screens)

#### 1.1 RecoveryMethodScreen - "J'ai déjà un compte"
**Purpose:** Allow users to recover existing account on new phone
**API Endpoints:**
- `POST /comptes/recuperation/debut` - Initiate recovery process
- `GET /comptes/recuperation/etapes` - Get recovery steps

**Key Components:**
- Button: "J'ai déjà un compte"
- Recovery method selector (SMS, email, recovery code)
- Phone number or email input
- Verification code input
- OTP validation

**Backend Liaison:**
```dart
Future<RecoverySessionResponse> initiateRecovery(String phoneOrEmail)
Future<bool> verifyRecoveryCode(String sessionId, String code)
```

**Navigation:**
- LoginScreen → RecoveryMethodScreen
- RecoveryMethodScreen → RecoveryVerificationScreen

---

#### 1.2 RecoveryVerificationScreen
**Purpose:** Verify recovery attempt via OTP
**API Endpoints:**
- `POST /comptes/recuperation/valider-code` - Validate recovery code
- `POST /comptes/recuperation/confirmer` - Confirm recovery

**Key Components:**
- OTP input (6 digits)
- Timer (5 min expiry)
- "Renvoyer code" button
- Recovery method options selector
- PIN creation after verification

**Backend Liaison:**
```dart
Future<bool> validateRecoveryCode(String sessionId, String code)
Future<AuthResponse> confirmRecovery(String sessionId, String newPin)
```

---

#### 1.3 RecoverySuccessScreen
**Purpose:** Confirm successful account recovery
**Display:**
- Account details (name, phone)
- Recovery date/time
- Security reminder
- Option to set new PIN

---

### 2. Recovery Code Management (2 screens)

#### 2.1 RecoveryCodeScreen - "Définir son code secret de récupération"
**Purpose:** Generate and display recovery code
**API Endpoints:**
- `POST /comptes/codes-recovery/generer` - Generate recovery code
- `GET /comptes/codes-recovery/mien` - Get existing code

**Key Components:**
- Large, easy-to-copy recovery code (12-16 chars)
- "Copier" button
- "Télécharger PDF" button
- "Envoyer par email" button
- Checkbox: "J'ai sauvegardé mon code"
- Warning: "Gardez ce code en sécurité"

**Security:**
- Displayed once only
- Never shown again in plain text
- User must confirm they saved it
- Can regenerate (invalidates old code)

---

#### 2.2 RecoveryCodeListScreen - "Codes de récupération"
**Purpose:** Manage recovery codes (regenerate, view history)
**API Endpoints:**
- `GET /comptes/codes-recovery` - List all recovery codes (hashed)
- `POST /comptes/codes-recovery/regenerer` - Generate new code
- `POST /comptes/codes-recovery/archiver` - Archive old code

**Key Components:**
- List of recovery codes (only last 4 digits visible)
- Creation date
- Last used date (if applicable)
- "Générer un nouveau code" button
- History log

---

### 3. Trusted Contact & Account Protection (2 screens)

#### 3.1 TrustedContactScreen - "Désigner un contact de confiance"
**Purpose:** Designate trusted contact for account recovery
**API Endpoints:**
- `POST /comptes/contact-confiance/proposer` - Propose trusted contact
- `GET /comptes/contact-confiance/mien` - Get current trusted contact
- `POST /comptes/contact-confiance/changer` - Change trusted contact

**Key Components:**
- Select existing contact from phone
- Or input phone number manually
- SMS invitation to designated contact
- Pending/Approved status
- Option to remove trusted contact

**Backend Liaison:**
```dart
Future<ContactInvitationResponse> proposeTrustedContact(String phoneNumber)
Future<TrustedContact> getTrustedContact()
Future<bool> revokeTrustedContact()
```

---

#### 3.2 TrustedContactInvitationScreen
**Purpose:** Trusted contact receives and accepts invitation
**API Endpoints:**
- `GET /comptes/contact-confiance/invitations` - Get pending invitations
- `POST /comptes/contact-confiance/accepter` - Accept invitation
- `POST /comptes/contact-confiance/refuser` - Reject invitation

**Key Components:**
- Invitation details (inviter name, phone)
- Explanation of trusted contact role
- "Accepter" / "Refuser" buttons
- Legal notice

---

### 4. Identity Verification (4 screens)

#### 4.1 IdentityVerificationConsentScreen - "Vérification d'identité: consentement"
**Purpose:** Get user consent for identity verification
**API Endpoints:**
- `GET /comptes/verification-identite/consentement` - Get consent form
- `POST /comptes/verification-identite/consentement` - Accept consent

**Key Components:**
- GDPR/Privacy notice
- Document collection notice
- Data usage explanation
- "J'accepte les conditions" checkbox
- "Continuer" button

---

#### 4.2 IdentityDocumentPhotoScreen - "Capture photos: recto, verso, selfie"
**Purpose:** Capture identity document and selfie photos
**API Endpoints:**
- `POST /comptes/verification-identite/upload-photos` - Upload photos

**Key Components:**
- Photo capture for:
  - Document front (recto)
  - Document back (verso)
  - Selfie with document
- Image preview & retry
- Quality checks (lighting, clarity)
- Base64 encode before upload

**Backend Liaison:**
```dart
Future<VerificationResponse> uploadIdentityPhotos({
  required String rectoImageBase64,
  required String versoImageBase64,
  required String selfieImageBase64,
})
```

---

#### 4.3 IdentityVerificationStatusScreen - "Suivi du dossier"
**Purpose:** Track identity verification progress
**API Endpoints:**
- `GET /comptes/verification-identite/statut` - Get verification status

**Key Components:**
- Status timeline:
  - ✓ Documents reçus (date/time)
  - ⏳ En analyse (estimated time)
  - ❌ Approuvé / Rejeté (with reason if rejected)
- "Voir les photos" option
- "Réessayer" if rejected
- Support contact link

**Statuses:**
- `PENDING` - Waiting for documents
- `SUBMITTED` - Documents received
- `IN_REVIEW` - Under analysis
- `APPROVED` - Verification complete
- `REJECTED` - Failed (show reason)

---

#### 4.4 IdentityApprovalNotificationScreen
**Purpose:** Notify user of verification approval/rejection
**Components:**
- Success/Failure animation
- Approval level (basic, full, advanced)
- Next steps
- Benefits unlocked (e.g., higher limits)

---

### 5. Account Security Alerts (1 screen)

#### 5.1 AccountAlertScreen - "Alerte et opposition: tentative de récupération"
**Purpose:** Alert user of recovery attempts and allow account opposition
**API Endpoints:**
- `GET /comptes/alertes` - Get security alerts
- `POST /comptes/opposition` - Block account (opposition)
- `POST /comptes/alertes/:id/confirmer` - Confirm legitimate attempt

**Key Components:**
- Alert list:
  - Date/time of attempt
  - IP address / Device info
  - Location (approximate)
  - Status (ALERTED / CONFIRMED / BLOCKED)
- Action buttons:
  - "C'était moi" (confirm legitimate)
  - "Ce n'était pas moi" (opposition)
- Notification preferences
- Contact support option

---

---

## TIER 3.5 - Profile & Sponsorship (2 screens)

### 6. Profile Management (1 screen)

#### 6.1 ProfileScreen - "Mon profil"
**Purpose:** View and manage account profile
**API Endpoints:**
- `GET /comptes/moi` - Get current account
- `PUT /comptes/moi` - Update profile
- `GET /comptes/moi/identite` - Get identity verification status

**Key Components:**
- User info display:
  - Nom complet
  - Numéro de téléphone
  - Email
  - Niveau d'identité (BASIC / VERIFIED / APPROVED)
- Edit capability for:
  - Name (with reverification)
  - Email
  - Phone
- Identity level badge
- Last login date
- Account creation date
- "Paramètres de sécurité" link
- "Déconnexion" button

**Identity Levels:**
- 🔵 BASIC - Phone number verified
- 🟡 VERIFIED - Email + identity docs submitted
- 🟢 APPROVED - Full identity verification complete

---

### 7. Sponsorship System (2 screens)

#### 7.1 SponsorshipProposalScreen - "Parrainages: proposer"
**Purpose:** Propose sponsorship to new user
**API Endpoints:**
- `POST /comptes/parrainages/proposer` - Propose sponsorship
- `GET /comptes/parrainages/propositions` - Get pending proposals

**Key Components:**
- Referrer info display
- "Copier le lien de parrainage" button (with QR code)
- Share options (WhatsApp, SMS, Email, Telegram)
- Rewards info (if applicable)
- Proposal history

**Backend Liaison:**
```dart
Future<String> generateSponsorshipLink() // Returns unique link
Future<SponsorshipProposal> proposeSponsor(String phoneNumber)
```

---

#### 7.2 SponsorshipResponseScreen - "Parrainages: accepter/refuser"
**Purpose:** Accept or reject sponsorship proposal
**API Endpoints:**
- `GET /comptes/parrainages/invitations` - Get pending invitations
- `POST /comptes/parrainages/accepter` - Accept sponsorship
- `POST /comptes/parrainages/refuser` - Reject sponsorship

**Key Components:**
- Sponsor info (name, phone, tontines count)
- "Accepter" / "Refuser" buttons
- Sponsor badge/rating
- Rewards explanation

---

---

## TIER 4 - Advanced Features (Priority Medium-High)

### 8. Tontine Membership Management (4 screens)

#### 8.1 PrivateTontineInvitationScreen - "Rejoindre tontine privée après invitation SMS"
**Purpose:** Join private tontine via SMS invitation
**API Endpoints:**
- `POST /cercles/:id/adhésions/via-sms` - Join via SMS token
- `GET /cercles/:id/details-invitation` - Get tontine details from SMS link

**Key Components:**
- SMS link handling (deep link)
- Tontine details preview
- "Rejoindre" button
- Terms acceptance
- Required info (name, phone)
- PIN confirmation

---

#### 8.2 PlaceExchangeScreen - "Échange de places: proposer/accepter/refuser"
**Purpose:** Manage place exchange requests
**API Endpoints:**
- `POST /cercles/:id/echanges/proposer` - Propose place exchange
- `GET /cercles/:id/echanges` - Get exchange requests
- `POST /cercles/:id/echanges/:id/accepter` - Accept exchange
- `POST /cercles/:id/echanges/:id/refuser` - Reject exchange

**Key Components:**
- List of members with positions
- Position display (e.g., "2ème passage")
- "Proposer un échange" button
- Exchange requests list:
  - From: member name
  - Their position
  - Proposed exchange target
  - "Accepter" / "Refuser" buttons
- Exchange history

---

#### 8.3 QuitTontineScreen - "Quitter une tontine avant d'avoir reçu"
**Purpose:** Allow member to quit tontine before receiving payout
**API Endpoints:**
- `POST /cercles/:id/quitter` - Quit tontine
- `GET /cercles/:id/consequences-depart` - Get quit consequences

**Key Components:**
- Warning: remaining payments required
- Outstanding contributions display
- Penalties explanation
- "Calculer les frais" button
- Confirmation checkbox
- "Quitter définitivement" button
- Contact support for exceptions

---

#### 8.4 TontineRegistryScreen - "Registre de la tontine et preuve d'intégrité"
**Purpose:** View tontine ledger and blockchain/cryptographic proof
**API Endpoints:**
- `GET /cercles/:id/registre` - Get tontine registry
- `GET /cercles/:id/preuve-integrite` - Get integrity proof
- `GET /cercles/:id/transactions` - Get transaction history

**Key Components:**
- Member list with positions
- Contribution tracking:
  - Paid / Pending / Overdue
  - Amount
  - Date
- Payout history
- "Télécharger le registre" (PDF)
- "Vérifier l'intégrité" button
  - Shows blockchain hash / signature
  - Verification status
- Transaction export

---

### 9. Dispute Management (1 screen)

#### 9.1 DisputeProofFileScreen - "Dossier de preuve après défaut d'un membre"
**Purpose:** Manage evidence for dispute after member default
**API Endpoints:**
- `POST /litiges/:id/pieces-justificatives` - Upload evidence
- `GET /litiges/:id/pieces` - Get evidence
- `PUT /litiges/:id/pieces/:id` - Update evidence

**Key Components:**
- Evidence upload area (drag & drop)
- File types accepted (PDF, PNG, JPG, MP4, etc.)
- Evidence list:
  - File name
  - Upload date
  - File size
  - Preview/Download option
- Description per file
- "Ajouter une pièce" button
- Evidence timeline
- Arbitrator review status

---

### 10. Financial Management (2 screens)

#### 10.1 AmountsDueScreen - "Sommes dues: frais, remises, remboursements"
**Purpose:** View all outstanding amounts
**API Endpoints:**
- `GET /comptes/sommes-dues` - Get amounts breakdown
- `GET /comptes/sommes-dues/detail` - Detailed breakdown

**Key Components:**
- Summary cards:
  - Cotisations dues
  - Frais (memberships, administrative)
  - Remises (discounts applied)
  - Remboursements (pending refunds)
- List view with:
  - Tontine name
  - Amount
  - Due date
  - Status (DUE / OVERDUE / PAID)
  - "Payer" button
- "Payer tout" option
- Export statement

---

#### 10.2 MobileMoneySimulationScreen - "Paiement Mobile Money simulé (pour la démo)"
**Purpose:** Simulate Mobile Money payment for demo/testing
**API Endpoints:**
- `POST /paiements/mobile-money/simuler` - Simulate payment
- `GET /paiements/mobile-money/statut` - Check payment status

**Key Components:**
- Phone number input
- Amount display
- Operator selector (MTN, Orange, Moov, etc.)
- "Simuler le paiement" button
- Payment flow:
  - PENDING → IN_PROGRESS → SUCCESS/FAILED
- Confirmation page with:
  - Transaction ID
  - Amount
  - Timestamp
  - Receipt option

---

### 11. Assistant & Automation (1 screen)

#### 11.1 OrganizerAssistantScreen - "Assistant de l'organisateur"
**Purpose:** Automation mode for tontine organizer
**API Endpoints:**
- `GET /cercles/:id/assistant` - Get assistant status
- `POST /cercles/:id/assistant/activer` - Toggle automation
- `GET /cercles/:id/assistant/journal` - Get action log
- `GET /cercles/:id/assistant/propositions` - Get pending decisions
- `POST /cercles/:id/assistant/decision` - Accept/reject proposal

**Key Components:**
- Mode selector:
  - Mode manuel (all decisions manual)
  - Mode autonome (automatic decisions, log review)
- Assistant journal:
  - Actions taken (auto)
  - Timestamp
  - Member affected
  - Amount/Details
- Pending propositions list:
  - Action description
  - "Approuver" / "Rejeter" buttons
- Statistics:
  - Auto-actions this month
  - Manual overrides
  - Success rate

**Assistant Actions (Autonomous):**
- Auto-send reminders 3 days before due date
- Auto-mark payment as late after due date
- Auto-flag suspicious patterns
- Auto-distribute payouts on schedule
- Auto-archive completed cycles

---

### 12. Cycle Management (1 screen)

#### 12.1 RelaunCycleScreen - "Relancer un nouveau cycle quand une tontine est terminée"
**Purpose:** Start new cycle after tontine completion
**API Endpoints:**
- `POST /cercles/:id/cycles/creer` - Create new cycle
- `GET /cercles/:id/cycles` - List all cycles
- `GET /cercles/:id/historique` - Get cycle history

**Key Components:**
- Completion summary:
  - Total amount managed
  - All payouts completed
  - Members in good standing
- New cycle configuration:
  - Same members or new?
  - Same amount?
  - Same rhythm?
  - New password/PIN?
- Existing members list (with checkboxes)
- "Inviter de nouveaux membres" button
- "Créer le nouveau cycle" button
- Historical cycle metrics

---

### 13. Advanced Tontine Options (1 screen)

#### 13.1 AdvancedTontineOptionsScreen - "Options avancées à la création"
**Purpose:** Configure advanced settings when creating tontine
**API Endpoints:**
- `POST /cercles` - Create tontine with options
- `PUT /cercles/:id` - Update tontine options

**Key Components:**
- Rhythm options:
  - "Tous les X jours" dropdown (1, 7, 15, 30 jours)
  - Custom interval input
- Score minimum:
  - Minimum trust score required for new members
  - Score level selector (BASIC / VERIFIED / APPROVED)
- Ordre de passage:
  - Random (tirage aléatoire)
  - Fixed (ordre fixé) - then enter member order
- Rappels (reminders):
  - Email reminders
  - SMS reminders
  - Push notifications
  - Frequency (1 day before, 3 days before, etc.)
- Choix de sa place:
  - Can members choose their order position?
  - Or auto-assigned?
- Additional security options:
  - Require 2FA for sensitive actions
  - Member approval for new joining members

---

### 14. Security & PIN Management (1 screen)

#### 14.1 PINReauthenticationScreen - "Demander le code PIN à la réouverture de l'app"
**Purpose:** Force PIN re-entry on app reopen
**API Endpoints:**
- `GET /comptes/securite/preference-pin` - Get PIN policy
- `PUT /comptes/securite/preference-pin` - Update PIN policy

**Key Components:**
- PIN re-authentication toggle
  - "Jamais" (Never)
  - "Toujours" (Always on reopen)
  - "Après X minutes" (configurable timeout)
  - "Si nouveau device" (on device change)
- Biometric option:
  - Enable/disable fingerprint/face as alternative to PIN
- Recent devices list:
  - Device name
  - Last login
  - Location
  - "Révoquer l'accès" button
- Session management:
  - Current sessions
  - "Déconnecter tous les autres" button

---

---

## Implementation Priority Matrix

### TIER 3 Timeline (Weeks 1-4 after MVP)
1. **Week 1-2:** Account Recovery (screens 1.1-1.3)
2. **Week 2:** Recovery Code Management (2.1-2.2)
3. **Week 2-3:** Trusted Contact (3.1-3.2)
4. **Week 3:** Identity Verification (4.1-4.4)
5. **Week 3:** Account Alerts (5.1)
6. **Week 4:** Profile & Sponsorship (6.1, 7.1-7.2)

### TIER 4 Timeline (Weeks 5-8)
1. **Week 5-6:** Tontine Membership (8.1-8.4)
2. **Week 6:** Dispute Evidence (9.1)
3. **Week 7:** Financial Management (10.1-10.2)
4. **Week 7:** Assistant & Cycle (11.1, 12.1)
5. **Week 8:** Advanced Options (13.1, 14.1)

---

## API Endpoints Summary

### Account & Security (15 endpoints)
- Recovery, codes, contacts, verification, alerts

### Profile (3 endpoints)
- Profile view/edit, sponsorship

### Tontines (8 endpoints)
- Membership, exchange, quit, registry

### Disputes (1 endpoint)
- Evidence management

### Payments (2 endpoints)
- Amounts due, mobile money simulation

### Automation (4 endpoints)
- Assistant, cycle management, options

**Total New Endpoints:** ~33 endpoints (23 already mapped in MVP)

---

## Notes for Implementation

1. **Security First**: All sensitive operations require PIN/biometric
2. **Offline Support**: Cache critical data for offline access
3. **Animations**: Match MVP splash screen animation style
4. **Accessibility**: WCAG 2.1 compliance
5. **Testing**: Backend endpoints must be ready before UI implementation
6. **Localization**: All text in French + internationalization support
7. **Error Handling**: Consistent error messages and recovery flows

---

## Status Tracking

- [ ] TIER 3.1 - Recovery (Week 1-2)
- [ ] TIER 3.2 - Recovery Codes (Week 2)
- [ ] TIER 3.3 - Trusted Contact (Week 2-3)
- [ ] TIER 3.4 - Identity Verification (Week 3)
- [ ] TIER 3.5 - Account Alerts (Week 3)
- [ ] TIER 3.6 - Profile & Sponsorship (Week 4)
- [ ] TIER 4.1 - Membership Management (Week 5-6)
- [ ] TIER 4.2 - Dispute Evidence (Week 6)
- [ ] TIER 4.3 - Financial Management (Week 7)
- [ ] TIER 4.4 - Automation (Week 7)
- [ ] TIER 4.5 - Advanced Options (Week 8)
