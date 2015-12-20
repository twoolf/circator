//
//  ConsentManager.swift
//  Circator
//
//  Created by Sihao Lu on 12/19/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import ResearchKit
import Locksmith

public typealias ConsentBlock = ((consented: Bool) -> Void)?

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
    
    private var consentHandler: ((consented: Bool) -> Void)?
    
    public var obtainedUserConsent: Bool {
        get {
            if let dictionary = Locksmith.loadDataForUserAccount("default"), consented = dictionary["consent"] as? Bool {
                return consented
            } else {
                return false
            }
        }
    }
    
    private func setUserConsentObtained(consentObtained: Bool = true) {
        do {
            try Locksmith.saveData(["consent" : consentObtained], forUserAccount: "default")
        } catch {
            print("Error: Cannot save to keychain!")
        }
    }
    
    private var loremIpsumText: String {
        return "The “Metabolic Compass” app will use surveys and phone sensor data to collect and track symptoms of metabolic syndrome: fatigue, cognitive difficulties, sleep disturbances, mood changes and reduction in exercise.  Participants are encouraged to keep a health diary."
    }
    
    private var loremIpsumShortText: String {
        return "We hope to learn the differences in how you navigate your daily tasks; to assess whether mobile devices and sensors can help better measure and manage our lives; and to ultimately improve the quality of life for people.  This study is unique in that it allows participants to step up as equal partners in both the monitoring and the sharing of their aggregate data as well as in the research process and analysis."
    }
    
    private var loremIpsumMediumText: String {
        return "How can we better manage the complexities of metabolic syndrome and the lives of those at risk for having metabolic diseases? We want to understand why some individuals at risk or having been diagnosed with metabolic syndrome recover faster than others, why their symptoms vary over time, and what can be done to make those symptoms improve.  We at Johns Hopkins University are proposing a new approach to allow participants to monitor their health in real time as well as partner in research studies. This app is designed for research and educational purposes only.  You should not rely on this information as a substitute for personal medical attention, diagnosis or hands-on treatment.  If you are concerned about your health or that of a child, please consult your family's health provider immediately.  Do not wait for a response from our professionals."
    }
    
    private var loremIpsumLongText: String {
        return "We hope to learn the differences in how people navigate through their days; to assess whether mobile devices and sensors can help better measure and manage metabolic disease and its progression; and to ultimately improve the quality of life for people. We are looking for volunteers to participate in this research study. If you are over 18 years old with a history of metabolic disease or without any history of metabolic disease, but at risk, we invite you to join this study. You do not need to have had metabolic syndrome to join this study."
    }
    
    private var eligibilitySteps: [ORKStep] {
        get {
            // Intro step
            let introStep = ORKInstructionStep(identifier: String(Identifier.EligibilityIntroStep))
            introStep.title = NSLocalizedString("Welcome to Metabolic Compass", comment: "")
            
            // Form step
            let formStep = ORKFormStep(identifier: String(Identifier.EligibilityFormStep))
            formStep.optional = false
            
            // Form items
            let formItem01 = ORKFormItem(identifier: String(Identifier.EligibilityFormItem01), text: "Are you over 18?", answerFormat: ORKAnswerFormat.eligibilityAnswerFormat())
            formItem01.optional = false
            let formItem02 = ORKFormItem(identifier: String(Identifier.EligibilityFormItem02), text: "Do you worry about your diet?", answerFormat: ORKAnswerFormat.eligibilityAnswerFormat())
            formItem02.optional = false
            let formItem03 = ORKFormItem(identifier: String(Identifier.EligibilityFormItem03), text: "Do you live in the United States of America?", answerFormat: ORKAnswerFormat.eligibilityAnswerFormat())
            formItem03.optional = false
            
            formStep.formItems = [
                formItem01,
                formItem02,
                formItem03
            ]
            
            // Ineligible step
            let ineligibleStep = ORKInstructionStep(identifier: String(Identifier.EligibilityIneligibleStep))
            ineligibleStep.title = NSLocalizedString("You are ineligible to join the study", comment: "")
            
            // Eligible step
            let eligibleStep = ORKCompletionStep(identifier: String(Identifier.EligibilityEligibleStep))
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
        let participantSignature = ORKConsentSignature(forPersonWithTitle: participantSignatureTitle, dateFormatString: nil, identifier: String(Identifier.ConsentDocumentParticipantSignature))
        
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
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM/dd/YY"
        let investigatorSignatureDateString = dateFormatter.stringFromDate(NSDate())
        
        let investigatorSignature = ORKConsentSignature(forPersonWithTitle: investigatorSignatureTitle, dateFormatString: nil, identifier: String(Identifier.ConsentDocumentInvestigatorSignature), givenName: investigatorSignatureGivenName, familyName: investigatorSignatureFamilyName, signatureImage: signatureImage, dateString: investigatorSignatureDateString)
        
        consentDocument.addSignature(investigatorSignature)
        
        /*
        This is the HTML content for the "Learn More" page for each consent
        section. In a real consent, this would be your content, and you would
        have different content for each section.
        
        If your content is just text, you can use the `content` property
        instead of the `htmlContent` property of `ORKConsentSection`.
        */
        let htmlContentString = "<ul><li>Lorem</li><li>ipsum</li><li>dolor</li></ul><p>\(loremIpsumLongText)</p><p>\(loremIpsumMediumText)</p>"
        
        /*
        These are all the consent section types that have pre-defined animations
        and images. We use them in this specific order, so we see the available
        animated transitions.
        */
        let consentSectionTypes: [ORKConsentSectionType] = [
            .Overview,
            .DataGathering,
            .Privacy,
            .DataUse,
            .TimeCommitment,
            .StudySurvey,
            .StudyTasks,
            .Withdrawing
        ]
        
        /*
        For each consent section type in `consentSectionTypes`, create an
        `ORKConsentSection` that represents it.
        
        In a real app, you would set specific content for each section.
        */
        var consentSections: [ORKConsentSection] = consentSectionTypes.map { contentSectionType in
            let consentSection = ORKConsentSection(type: contentSectionType)
            
            consentSection.summary = loremIpsumShortText
            
            if contentSectionType == .Overview {
                consentSection.htmlContent = htmlContentString
            }
            else {
                consentSection.content = loremIpsumLongText
            }
            
            return consentSection
        }
        
        /*
        This is an example of a section that is only in the review document
        or only in the generated PDF, and is not displayed in `ORKVisualConsentStep`.
        */
        let consentSection = ORKConsentSection(type: .OnlyInDocument)
        consentSection.summary = NSLocalizedString(".OnlyInDocument Scene Summary", comment: "")
        consentSection.title = NSLocalizedString(".OnlyInDocument Scene", comment: "")
        consentSection.content = loremIpsumLongText
        
        consentSections += [consentSection]
        
        // Set the sections on the document after they've been created.
        consentDocument.sections = consentSections
        
        return consentDocument
    }

    private var consentSteps: [ORKStep] {
        /*
        Informed consent starts by presenting an animated sequence conveying
        the main points of your consent document.
        */
        let visualConsentStep = ORKVisualConsentStep(identifier: String(Identifier.VisualConsentStep), document: consentDocument)
        
        let investigatorShortDescription = NSLocalizedString("Johns Hopkins University", comment: "")
        let investigatorLongDescription = NSLocalizedString("Institution and its partners", comment: "")
        let localizedLearnMoreHTMLContent = NSLocalizedString("Funded, in part, by NIH", comment: "")
        
        /*
        If you want to share the data you collect with other researchers for
        use in other studies beyond this one, it is best practice to get
        explicit permission from the participant. Use the consent sharing step
        for this.
        */
        let sharingConsentStep = ORKConsentSharingStep(identifier: String(Identifier.ConsentSharingStep), investigatorShortDescription: investigatorShortDescription, investigatorLongDescription: investigatorLongDescription, localizedLearnMoreHTMLContent: localizedLearnMoreHTMLContent)
        
        /*
        After the visual presentation, the consent review step displays
        your consent document and can obtain a signature from the participant.
        
        The first signature in the document is the participant's signature.
        This effectively tells the consent review step which signatory is
        reviewing the document.
        */
        let signature = consentDocument.signatures!.first
        
        let reviewConsentStep = ORKConsentReviewStep(identifier: String(Identifier.ConsentReviewStep), signature: signature, inDocument: consentDocument)
        
        // In a real application, you would supply your own localized text.
        reviewConsentStep.text = loremIpsumText
        reviewConsentStep.reasonForConsent = loremIpsumText
        
        return [
            visualConsentStep,
            sharingConsentStep,
            reviewConsentStep
        ]
    }
    
    private func consentTaskWithEligibilitySection(withEligibility: Bool = true) -> ORKTask {
        if withEligibility {
            let consentTask = ORKNavigableOrderedTask(identifier: String(Identifier.EligibilityAndConsentTask), steps: Array([eligibilitySteps, consentSteps].flatten()))
            
            // Build navigation rules.
            var resultSelector = ORKResultSelector(stepIdentifier: String(Identifier.EligibilityFormStep), resultIdentifier: String(Identifier.EligibilityFormItem01))
            let predicateFormItem01 = ORKResultPredicate.predicateForBooleanQuestionResultWithResultSelector(resultSelector, expectedAnswer: true)
            
            resultSelector = ORKResultSelector(stepIdentifier: String(Identifier.EligibilityFormStep), resultIdentifier: String(Identifier.EligibilityFormItem02))
            let predicateFormItem02 = ORKResultPredicate.predicateForBooleanQuestionResultWithResultSelector(resultSelector, expectedAnswer: true)
            
            resultSelector = ORKResultSelector(stepIdentifier: String(Identifier.EligibilityFormStep), resultIdentifier: String(Identifier.EligibilityFormItem03))
            let predicateFormItem03 = ORKResultPredicate.predicateForBooleanQuestionResultWithResultSelector(resultSelector, expectedAnswer: false)
            
            let predicateEligible = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateFormItem01, predicateFormItem02, predicateFormItem03])
            
            let predicateRule = ORKPredicateStepNavigationRule(resultPredicates: [predicateEligible], destinationStepIdentifiers: [String(Identifier.EligibilityEligibleStep)], defaultStepIdentifier: nil, validateArrays: false)
            
            consentTask.setNavigationRule(predicateRule, forTriggerStepIdentifier:String(Identifier.EligibilityFormStep))
            
            // Add end direct rules to skip unneeded steps
            let directRule = ORKDirectStepNavigationRule(destinationStepIdentifier: ORKNullStepIdentifier)
            consentTask.setNavigationRule(directRule, forTriggerStepIdentifier:String(Identifier.EligibilityIneligibleStep))
            return consentTask
        } else {
            return ORKOrderedTask(identifier: String(Identifier.ConsentTask), steps: consentSteps)
        }
    }
    
    public func checkConsentWithBaseViewController(viewController: UIViewController, withEligibility: Bool = true, consentBlock: ConsentBlock) {
        self.consentHandler = consentBlock
        if obtainedUserConsent == false {
            let taskViewController = ORKTaskViewController(task: consentTaskWithEligibilitySection(withEligibility), taskRunUUID: nil)
            taskViewController.delegate = self
            viewController.presentViewController(taskViewController, animated: true, completion: nil)
        } else {
            self.consentHandler?(consented: true)
        }
    }
    
    // MARK: - Task view controller delegate
    
    public func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        switch reason {
        case .Completed:
            let document = consentDocument.copy() as! ORKConsentDocument
            let signatureResult = taskViewController.result.stepResultForStepIdentifier(String(Identifier.ConsentReviewStep))?.firstResult as! ORKConsentSignatureResult
            signatureResult.applyToDocument(document)
            document.makePDFWithCompletionHandler { (data, error) -> Void in
                guard error == nil else {
                    return
                }
                let path = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent("consent.pdf")
                print(path)
                data!.writeToFile(path, atomically: true)
            }
            setUserConsentObtained()
        case .Discarded:
            break
        case .Failed:
            print(error)
        case .Saved:
            break
        }
        taskViewController.dismissViewControllerAnimated(true) {
            self.consentHandler?(consented: reason == .Completed)
        }
    }
    
}
