//
//  ConsentManager.swift
//  MetabolicCompass
//
//  Created by Sihao Lu on 12/19/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import ResearchKit
import Locksmith
import Async

public typealias ConsentBlock = ((_ consented: Bool, _ givenName: String?, _ familyName: String?) -> Void)?

private let ConsentFilePathKey = "CMConsentFileKey"
private let unnamedAccount = "default"

/**
 Interacts with ResearchKit to control the electronic consent process.  Note that this flows from work with our Johns Hopkin IRB panel for consent of the process.  The ResearchKit framework supports a range of questions and their responses as well as the creation of the final pdf document.  
 
 */
public class ConsentManager: NSObject, ORKTaskViewControllerDelegate {
    private enum Identifier {
        case EligibilityTask

        case EligibilityIntroStep
        case EligibilityFormStep
        case EligibilityQuestionStep
        
        case EligibilityEligibleStep
        case EligibilityIneligibleStep
        
        case EligibilityFormItem01
        case EligibilityFormItem02
        case EligibilityFormItem03
        
        case ConsentDocumentParticipantSignature
        case ConsentDocumentInvestigatorSignature
        case VisualConsentStep
        case ConsentSharingStep
        case ConsentReviewStep
        
        case EligibilityAndConsentTask
        case ConsentTask
    }
    
    public static let sharedManager = ConsentManager()
    
    private var consentHandler: ((_ consented: Bool, _ givenName: String?, _ familyName: String?) -> Void)?
    
    public func resetConsentFilePath () {
        do {
            try Locksmith.deleteDataForUserAccount(userAccount: unnamedAccount)
        } catch {
            print ("Can't delete default user data")
        }
    }
    
    public func getConsentFilePath() -> String? {
        if let dictionary = Locksmith.loadDataForUserAccount(userAccount: unnamedAccount),
            let consentFilePath = dictionary["consentfile"] as? String
        {
            return consentFilePath
        }
        return nil
    }
    
    private func setConsentFilePath(consentFilePath: String) {
        do {
            if let _ = Locksmith.loadDataForUserAccount(userAccount: unnamedAccount)
            {
                try Locksmith.updateData(data: ["consentfile": consentFilePath], forUserAccount: unnamedAccount)
            } else {
                try Locksmith.saveData(data: ["consentfile": consentFilePath], forUserAccount: unnamedAccount)
            }
        } catch {
            print("Error: Cannot save to keychain!")
        }
    }
    
    public func removeConsentFile(consentFilePath: String) {
        do {
            print("Removing file at: \(consentFilePath)")
            try FileManager.default.removeItem(atPath: consentFilePath)
        }
        catch let error as NSError {
            print("Failed to remove consent file: \(error)")
        }
    }

    private var welcomeText: String {
        return "This simple walkthrough will explain the research study, the impact it may have on your life and will allow you to provide your consent to participate."
    }
    
    private var welcomeSectionText: String {
        return "We hope to learn the differences in how you navigate your daily tasks; to assess whether mobile devices and sensors can help better measure and manage our lives; and to ultimately improve the quality of life for people.  This study is unique in that it allows participants to step up as equal partners in both the monitoring and the sharing of their aggregate data as well as in the research process and analysis."
    }
    
    private var sensorDataText: String {
        return "This study will gather sensor data from your iPhone and your personal devices with your permission."
    }
    
    private var dataProcessingText: String {
        return "Your study data (survey and sensors) will be combined with similar data from other participants."
    }
    
    private var protectingYourData: String {
        return "We will replace your name with a random code.  The coded data will be encrypted and stored on a secure Amazon Web Services Database to prevent improper access"
    }
    
    private var dataUse: String {
        return "The data will be used for research and may be shared with qualified research partners worldwide."
    }
    
    private var withdrawing: String {
        return "Your participation is voluntary.  You may withdraw your consent and discontinue participation at any time."
    }
    
    private var potentialBenefits: String {
        return "You will be able to visualize your data and potentially learn more about trends in your health."
    }
    
    private var issuesToConsider: String {
        return "This research is not a treatment study.  Some questions may make you feel uncomfortable.  Simply do not respond to those questions."
    }
    
    private var riskToPrivacy: String {
        return "We will make every effort to protect your information, and believe that the risk to your privacy is small"
    }
    
    private var PotentialBenefitsLong: String {
        return "How can we better manage the complexities of metabolic syndrome and the lives of those at risk for having metabolic diseases? We want to understand why some individuals at risk or having been diagnosed with metabolic syndrome recover faster than others, why their symptoms vary over time, and what can be done to make those symptoms improve.  We at Johns Hopkins University are proposing an approach to allow participants to monitor their metabolic health in real time as well as partner in research studies. This app is designed for research and educational purposes only.  You should not rely on this information as a substitute for personal medical attention, diagnosis or hands-on treatment.  If you are concerned about your health or that of a child, please consult your family's health provider immediately.  Do not wait for a response from our professionals."
    }
    
    private var ConsiderLongText: String {
        return "We hope to learn the differences in how people navigate through their days; to assess whether mobile devices and sensors can help better measure and manage metabolic disease and its progression; and to ultimately improve the quality of life for people. We are looking for volunteers to participate in this research study. If you are over 18 years old with a history of metabolic disease or without any history of metabolic disease, but at risk, we invite you to join this study. You do not need to have had metabolic syndrome to join this study."
    }
    
    private var eligibilitySteps: [ORKStep] {
        get {
            // Intro step
            let introStep = ORKInstructionStep(identifier: String(describing: Identifier.EligibilityIntroStep))
            introStep.title = NSLocalizedString("Welcome to Metabolic Compass", comment: "")
            
            // Form step
            let formStep = ORKFormStep(identifier: String(describing: Identifier.EligibilityFormStep))
            formStep.isOptional = false
            
            // Form items
            let formItem01 = ORKFormItem(identifier: String(describing: Identifier.EligibilityFormItem01), text: "Are you over 18?", answerFormat: ORKAnswerFormat.eligibilityAnswerFormat())
            formItem01.isOptional = false
            let formItem02 = ORKFormItem(identifier: String(describing: Identifier.EligibilityFormItem02), text: "Do you worry about your diet?", answerFormat: ORKAnswerFormat.eligibilityAnswerFormat())
            formItem02.isOptional = false
            let formItem03 = ORKFormItem(identifier: String(describing: Identifier.EligibilityFormItem03), text: "Do you live in the United States of America?", answerFormat: ORKAnswerFormat.eligibilityAnswerFormat())
            formItem03.isOptional = false
            
            formStep.formItems = [
                formItem01,
                formItem02,
                formItem03
            ]
            
            // Ineligible step
            let ineligibleStep = ORKInstructionStep(identifier: String(describing: Identifier.EligibilityIneligibleStep))
            ineligibleStep.title = NSLocalizedString("You are ineligible to join the study", comment: "")
            
            // Eligible step
            let eligibleStep = ORKCompletionStep(identifier: String(describing: Identifier.EligibilityEligibleStep))
            eligibleStep.title = NSLocalizedString("You are eligible to join the study", comment: "")
            
            return [
                introStep,
                formStep,
                ineligibleStep,
                eligibleStep
            ]
        }
    }
    
    private var consentDocument: ORKConsentDocument {
        
        let consentDocument = ORKConsentDocument()
        
        /*
        This is the title of the document, displayed both for review and in
        the generated PDF.
        */
        consentDocument.title = NSLocalizedString("Metabolic Compass", comment: "How can we better understand and manage the problems associated with metabolic syndrome?")
        
        // This is the title of the signature page in the generated document.
        consentDocument.signaturePageTitle = NSLocalizedString("Consent", comment: "")
        
        /*
        This is the line shown on the signature page of the generated document,
        just above the signatures.
        */
        consentDocument.signaturePageContent = NSLocalizedString("I agree to participate in this research study.", comment: "")
        
        /*
        Add the participant signature, which will be filled in during the
        consent review process. This signature initially does not have a
        signature image or a participant name; these are collected during
        the consent review step.
        */
        let participantSignatureTitle = NSLocalizedString("Participant", comment: "")
        let participantSignature = ORKConsentSignature(forPersonWithTitle: participantSignatureTitle, dateFormatString: nil, identifier: String(describing: Identifier.ConsentDocumentParticipantSignature))
        
        consentDocument.addSignature(participantSignature)
        
        /*
        Add the investigator signature. This is pre-populated with the
        investigator's signature image and name, and the date of their
        signature. If you need to specify the date as now, you could generate
        a date string with code here.
        
        This signature is only used for the generated PDF.
        */
        let signatureImage = UIImage(named: "tbw_signature")!
        let investigatorSignatureTitle = NSLocalizedString("Professor", comment: "")
        let investigatorSignatureGivenName = NSLocalizedString("Thomas", comment: "")
        let investigatorSignatureFamilyName = NSLocalizedString("Woolf", comment: "")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/YY"
        let investigatorSignatureDateString = dateFormatter.string(from: Date())
        
        let investigatorSignature = ORKConsentSignature(forPersonWithTitle: investigatorSignatureTitle, dateFormatString: nil, identifier: String(describing: Identifier.ConsentDocumentInvestigatorSignature), givenName: investigatorSignatureGivenName, familyName: investigatorSignatureFamilyName, signatureImage: signatureImage, dateString: investigatorSignatureDateString)
        
        consentDocument.addSignature(investigatorSignature)
        
        /*
        This is the HTML content for the "Learn More" page for each consent
        section. In a real consent, this would be your content, and you would
        have different content for each section.
        
        If your content is just text, you can use the `content` property
        instead of the `htmlContent` property of `ORKConsentSection`.
        */

        let sensorDataContentString = "<body><p>You have the option to contribute activity data collected through:</p><ul><li>The sensors on your iPhone or any wearable activity device (like iPhone, iPod, Apple Watch, or third-party device) </li><li>Other applications and data available through Apple Health app.</li></ul><p>You can choose not to provide this data and still participate in the study.</p><p>We will NOT access your personal contacts, personal photos, text or email messages.</p></p></body>"
        
        let protectingDataString = "<body><p>We will electronically process your data.<br /><br />We will separate your account information (name, email, contact information, etc.) from your study data (your responses to surveys and the measurements from the phone itself when you perform activities).<br /><br />We will combine your coded study data (without your name) with those of other study participants to be analyzed.<br /><br />WE WILL NEVER SELL, RENT OR LEASE YOUR CONTACT INFORMATION. <br /><br /></body>"
        
        let dataUseString = "<body><p>By analyzing the data from all app users, we may be able to better understand how people adjust their activity levels, their eating profiles, and their sleep patterns to achieve optimal health.</p><p>We hope that together we can learn:</p><ul><li>The ways you have found to navigate from poor health to improved health</li><li>To help us assess whether mobile devices and sensors can measure and better understand our own behavior and contribute (in anonymous aggregate) to improving the health of others as well</li><li>Ultimately to improve the quality of life for all those either suffering from or at risk for metabolic disease.</li></ul></body>"
        
        let withDrawingString = "<body><p>Your participation in this study is voluntary. You may decide not to participate or you may leave the study at any time. If you withdraw from the study, we will stop collecting new data, but the coded study data that you have already provided, and that have already been distributed will not be able to be destroyed or deleted.</p><p>To withdraw from this study please contact  Dr. Thomas Woolf by email <a href='mailto:twoolf@jhmi.edu'>twoolf@jhmi.edu</a>  or call <a href='tel:14106142643'>+1-410-614-2643</a> or tap on the 'Leave Study' link in the profile page of the application.</p></body>"
        
        let sharingResearchString = "<body><p>This study is designed to share your anonymous data:</p><p><strong>Share broadly with the research world:</strong>  You can choose to share your coded study data with qualified researchers worldwide for use in this research and beyond. Coded study data is data that does not include personal information such as your name or email. Qualified researchers are registered users who have agreed to use the data in an ethical manner for research purposes, and have agreed to not attempt to re-identify you. If you choose to share your coded study data, the coded data will be added to a shared dataset available to qualified researchers on our study servers. (https://www.metaboliccompass.com). Johns Hopkins University will have no oversight on the future research that qualified researchers may conduct with the coded study data.<p>If required by law, your data (study data and account information), and the signed consent form may be disclosed to:</p><ul><li>The US National Institute of health, Department of Health and Human Services agencies, Office for Human Research Protection, and other agencies as required,</li><li>Institutional Review Board who monitors the safety, effectiveness and conduct of the research being conducted,</li><li>Others, if the law requires</li></ul><p>The results of this research study may be presented at meetings or in publications. If the results of this study are made public, only coded study data will be used, that is, your personal information will not be disclosed.</p>For additional information review the study website <a href='https://MetabolicCompass.com'>MetabolicCompass.com</a> </p></body>"
        
        /*
        These are all the consent section types that have pre-defined animations
        and images. We use them in this specific order, so we see the available
        animated transitions.
        */
        let consentSectionTypes: [ORKConsentSectionType] = [
            .overview,
            .dataGathering,
            .privacy,
            .dataUse,
            .timeCommitment,
            .studySurvey,
            .studyTasks,
            .withdrawing
        ]
        
        /*
        For each consent section type in `consentSectionTypes`, create an
        `ORKConsentSection` that represents it.
        */
        var consentSections: [ORKConsentSection] = consentSectionTypes.map { contentSectionType in
            let consentSection = ORKConsentSection(type: contentSectionType)
            
            if contentSectionType == .overview {
                consentSection.summary = welcomeText
                consentSection.htmlContent = welcomeSectionText
            }
            else if contentSectionType == .dataGathering {
                consentSection.summary = dataProcessingText
                consentSection.htmlContent = sensorDataContentString
            }
            else if contentSectionType == .privacy {
                consentSection.summary = protectingYourData
                consentSection.htmlContent = protectingDataString
            }
            else if contentSectionType == .dataUse {
                consentSection.summary = dataUse
                consentSection.htmlContent = dataUseString
            }
            else if contentSectionType == .timeCommitment {
                consentSection.summary = potentialBenefits
                consentSection.htmlContent = PotentialBenefitsLong
            }
            else if contentSectionType == .studySurvey {
                consentSection.summary = issuesToConsider
                consentSection.htmlContent = ConsiderLongText
            }
            else if contentSectionType == .studyTasks {
                consentSection.summary = riskToPrivacy
                consentSection.htmlContent = sharingResearchString
            }
            else if contentSectionType == .withdrawing {
                consentSection.summary = withdrawing
                consentSection.htmlContent = withDrawingString
            }
            
            return consentSection
        }
        
        // Set the sections on the document after they've been created.
        consentDocument.sections = consentSections
        
        return consentDocument
    }

    private var consentSteps: [ORKStep] {
        /*
        Informed consent starts by presenting an animated sequence conveying
        the main points of your consent document.
        */
        let visualConsentStep = ORKVisualConsentStep(identifier: String(describing: Identifier.VisualConsentStep), document: consentDocument)
        
        let investigatorShortDescription = NSLocalizedString("Johns Hopkins University", comment: "")
        let investigatorLongDescription = NSLocalizedString("Johns Hopkins University and its partners", comment: "")
        let localizedLearnMoreHTMLContent = NSLocalizedString("This study shares your data:</p><p><strong>By consenting to join this study you will be letting researchers access your anonymous data:</strong>  You will be sharing your coded study data (made anonymous) with qualified researchers worldwide for use in this research and beyond. Coded study data is data that does not include personal information such as your name or email. Qualified researchers are registered users who have agreed to use the data in an ethical manner for research purposes, and have further agreed to not attempt to re-identify you. If you choose to share your coded study data, the coded data will be added to a shared dataset available to qualified researchers on the Metabolic Compass servers. (https://app.metaboliccompass.com). Johns Hopkins University will have no oversight on the future research that qualified researchers may conduct with the coded study data.</p><p><strong> ><p>If required by law, your data (study data and account information), and the signed consent form may be disclosed to:</p><ul><li>The US National Institute of health, Department of Health and Human Services agencies, Office for Human Research Protection, and other agencies as required,</li><li>Institutional Review Board who monitors the safety, effectiveness and conduct of the research being conducted,</li><li>Others, if the law requires</li></ul><p>The results of this research study may be presented at meetings or in publications. If the results of this study are made public, only coded study data will be used, that is, your personal information will not be disclosed.</p> For additional information review the study website <a href='https://app.metaboliccompass.com'>app.metaboliccommpass.com</a> </p></body>", comment: "")

        
        /*
        If you want to share the data you collect with other researchers for
        use in other studies beyond this one, it is best practice to get
        explicit permission from the participant. Use the consent sharing step
        for this.
        */
        let sharingConsentStep = ORKConsentSharingStep(identifier: String(describing: Identifier.ConsentSharingStep), investigatorShortDescription: investigatorShortDescription, investigatorLongDescription: investigatorLongDescription, localizedLearnMoreHTMLContent: localizedLearnMoreHTMLContent)
        
        /*
        After the visual presentation, the consent review step displays
        your consent document and can obtain a signature from the participant.
        
        The first signature in the document is the participant's signature.
        This effectively tells the consent review step which signatory is
        reviewing the document.
        */
        let signature = consentDocument.signatures!.first
        
        let reviewConsentStep = ORKConsentReviewStep(identifier: String(describing: Identifier.ConsentReviewStep), signature: signature, in: consentDocument)
        
        // In a real application, you would supply your own localized text.
        reviewConsentStep.text = ConsiderLongText
        reviewConsentStep.reasonForConsent = welcomeSectionText

        return [
            visualConsentStep,
            sharingConsentStep,
            reviewConsentStep
        ]
    }
 
    private func consentTaskWithEligibilitySection() -> ORKTask {
        let consentTask = ORKNavigableOrderedTask(identifier: String(describing: Identifier.EligibilityAndConsentTask), steps: Array([eligibilitySteps, consentSteps].joined()))
        
        // Build navigation rules.
        var resultSelector = ORKResultSelector(stepIdentifier: String(describing: Identifier.EligibilityFormStep), resultIdentifier: String(describing: Identifier.EligibilityFormItem01))
        let predicateFormItem01 = ORKResultPredicate.predicateForBooleanQuestionResult(with: resultSelector, expectedAnswer: true)
        
        resultSelector = ORKResultSelector(stepIdentifier: String(describing: Identifier.EligibilityFormStep), resultIdentifier: String(describing: Identifier.EligibilityFormItem02))
        let predicateFormItem02 = ORKResultPredicate.predicateForBooleanQuestionResult(with: resultSelector, expectedAnswer: true)
        
        resultSelector = ORKResultSelector(stepIdentifier: String(describing: Identifier.EligibilityFormStep), resultIdentifier: String(describing: Identifier.EligibilityFormItem03))
        let predicateFormItem03 = ORKResultPredicate.predicateForBooleanQuestionResult(with: resultSelector, expectedAnswer: true)
        
        let predicateEligible = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateFormItem01, predicateFormItem02, predicateFormItem03])
        
        let predicateRule = ORKPredicateStepNavigationRule(resultPredicates: [predicateEligible], destinationStepIdentifiers: [String(describing: Identifier.EligibilityEligibleStep)], defaultStepIdentifier: nil, validateArrays: false)
        
        consentTask.setNavigationRule(predicateRule, forTriggerStepIdentifier:String(describing: Identifier.EligibilityFormStep))
        
        // Add end direct rules to skip unneeded steps
        let directRule = ORKDirectStepNavigationRule(destinationStepIdentifier: ORKNullStepIdentifier)
        consentTask.setNavigationRule(directRule, forTriggerStepIdentifier:String(describing: Identifier.EligibilityIneligibleStep))
        return consentTask
    }
    
    public func checkConsentWithBaseViewController(viewController: UIViewController, consentBlock: ConsentBlock) {
        self.consentHandler = consentBlock
        guard UserManager.sharedManager.hasUserId() else {
            let taskViewController = ORKTaskViewController(task: consentTaskWithEligibilitySection(), taskRun: nil)
            taskViewController.delegate = self
            taskViewController.view.tintColor = Theme.universityDarkTheme.backgroundColor
            viewController.present(taskViewController, animated: true, completion: nil)
            return
        }
        self.consentHandler?(true, nil, nil)
    }
   
    // MARK: - Task view controller delegate

    public func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
     var completedToDocument = false
     var givenName: String? = nil
     var familyName: String? = nil
     switch reason {
     case .completed:
//     let document = consentDocument.copy() as! ORKConsentDocument
//     if let consentStep = taskViewController.result.stepResultForStepIdentifier(String(Identifier.ConsentReviewStep)),
//     let signatureResult = consentStep.firstResult as? ORKConsentSignatureResult
//     {
//     completedToDocument = signatureResult.consented
//     givenName = signatureResult.signature?.givenName
//     familyName = signatureResult.signature?.familyName
     
//     signatureResult.applyToDocument(document)
//     document.makePDF { (data, error) -> Void in
     guard error == nil else {
     return
     }
     let path = (NSTemporaryDirectory() as NSString).appendingPathComponent("consent.pdf")
     self.setConsentFilePath(consentFilePath: path)
//     data!.write(to: try path.asURL()!, options: true)
//     }
     case .discarded:
        return
     case .failed:
        return
     case .saved:
        return
    
     }
     
//     case .discarded:
//     break
//     case .failed:
//     log.error("Consent view failed: \(error)")
//     case .saved:
//     break
     }
//     taskViewController.dismiss(animated: true) {
//     self.consentHandler?(completedToDocument, givenName, familyName)
//     }
//    }
/*    public func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        var completedToDocument = false
        var givenName: String? = nil
        var familyName: String? = nil
        switch reason {
        case .completed:
            let document = consentDocument.copy() as! ORKConsentDocument
            if let consentStep = taskViewController.result.stepResultForStepIdentifier(String(Identifier.ConsentReviewStep)),
                   let signatureResult = consentStep.firstResult as? ORKConsentSignatureResult
            {
                completedToDocument = signatureResult.consented
                givenName = signatureResult.signature?.givenName
                familyName = signatureResult.signature?.familyName

                signatureResult.applyToDocument(document)
                document.makePDF { (data, error) -> Void in
                    guard error == nil else {
                        return
                    }
                    let path = (NSTemporaryDirectory() as NSString).appendingPathComponent("consent.pdf")
                    self.setConsentFilePath(consentFilePath: path)
                    data!.write(to: try path.asURL()!, options: true)
                }
            }

        case .discarded:
            break
        case .failed:
            log.error("Consent view failed: \(error)")
        case .saved:
            break
        }
        taskViewController.dismiss(animated: true) {
            self.consentHandler?(completedToDocument, givenName, familyName)
        }
    } */
}
